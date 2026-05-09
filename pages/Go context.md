- Package `context` provides library for working *context*, a way to pass around and handle request-scoped values, including deadlines and cancellation signals in [[Go]]
- The main type is the interface `context.Context`
	- Most of the time, we just use the implementation from package `context` without knowing about underlying type
- # context.Context
	- > Note: we'll call `context.Context` as just `Context`
	- `type Context interface{..}` defines some Go methods:
	  ```go
	  type Context interface {
	  	Deadline() (deadline time.Time, ok bool)
	  	Done() <-chan struct{}
	    	Err() error
	  	Value(key any) any
	  }
	  ```
		- **Note: `key` in `Value` is _typed_**
		- This means that, if we have `type String string`, then `Value(String("hi"))` and `Value("hi")` will return different values
		- This allows us to store values with essentially the same underlying key data as separate slot, separated by the key's Go type
	- The interface suggests `Context` is mostly used to control cancellation and synchronization, as well as store some key-value pairs (`Value`)
	- To create a new, vanilla `Context`, we can use `context.Background` which creates *background* context in the current scope
	- ## Parent-child context
		- The interface does not imply parent-child relationship at all
		- But package `context` provides an implementation(s) that lets us create a new `Context` (child) out of an existing `Context`
		- In fact,  API in package `context` forces us to recognize this parent-child pattern when we want to do cancels or deadlines:
		  ```go
		  func foo() {
		    // New, vanilla context
		    // This would be our "parent"
		    ctx := context.Background()
		  
		    // Create a child context a long with a `cancel` chanel
		    ctxChild, cancel := context.WithCancel(ctx)
		  }
		  ```
		- Parent can propagate their cancellations/deadlines to children, **but not vice versa**, as shown in [one of the examples](((69ff7579-672c-4bef-b921-eb5afed956b4)))
- # Go context cancellation
	- We can create a `Context` with the ability to be "canceled" with `context.WithCancel`:
	  ```go
	  ctx, cancel := context.WithCancel(context.Background())
	  ```
	  When `cancel` is called, `ctx` is *canceled*
	- When `ctx` is canceled:
		- `ctx.Err()` returns an error saying context is canceled
		- The channel from `ctx.Done()` finally receive a value
		- > Use `ctx.Err()` if we want to check for `ctx` status immediately.
		  > Use `select` over `ctx.Done()` if we want to block and wait for something `ctx`'s doing to finish.
	- We use `ctx.Err()` if we want to check for `ctx` status immediately
	- We `select` over `ctx.Done()` if we want to block and wait for something `ctx`'s doing to finish
	- canceled parents also cancel their children
- # Go context deadline
	- We can create a `Context` with a timeout deadline with `context.WithTimeout`:
	  ```go
	  // Creates a Context that will be automatically canceled in 10s
	  // or manually when `cancel` is called
	  ctx, cancel := context.WithTimeout(context.Background(), time.Second*10)
	  ```
	- Deadlines are just timed cancellations, so the assumptions from cancellation also hold
	- The only difference is the error message now being `deadline exceeded`
- # Examples
	- ## Parent-child cascade
	  id:: 69ff7579-672c-4bef-b921-eb5afed956b4
		- ```go
		  /*
		  This program demonstrates how Go context cancellation propagation works
		  
		  # What it does
		  It simulates concurrent work, so we can observe how Go context works.
		  The dummy work is simple: concurrent prints for ints in range [0, 10] with 3 contexts:
		  - c1: original context, used only for work=0
		  - c2: c1's child, with timeout, used for any even works
		  - c3: c2's child, with cancel, used for any odd works
		  
		  Work is done in function f, which loops every 1s forever until the work is done.
		  Every 1s, it inspects whether the context is done for, and print to screen accordingly
		  If the context is not yet canceled, the program prints `work` along with the work number
		  If the context is done, the program prints `done` along with the work number
		  
		  ## Expectation:
		  c2 should be forced done after 3s without us having to call any cancel functions.
		  And since c3 is c2's direct child, it should be forced canceled as well.
		  But since c1 has no parent, it should not be canceled and continue to do work.
		  
		  - At start, all of the works should start concurrently
		  - After 3s, c2 is canceled, so the all c2 works are done
		  - But since c2 has a child, c3, the cancellation propagates to c3 and all c3 works are done
		  - Only work=0 (c1) is left printing "work", the rest are done
		  
		  ## Key takeaways:
		  1. Parents prograpagate cancellations to children, not vice versa
		  2. Deadlines are just cancellations with a timer
		  3. Context.Done and Context.Err are 2 sides of the same coins
		  4. Done channels are long-lived and could continue to receive values after context is canceled, the same is also true for Context.Err
		  
		  */
		  
		  package main
		  
		  import (
		  	"context"
		  	"fmt"
		  	"sync"
		  	"time"
		  )
		  
		  func main() {
		  	c1 := context.Background()
		  	c2, _ := context.WithTimeout(c1, time.Second*3)
		  	c3, _ := context.WithCancel(c2)
		  	var wg sync.WaitGroup
		  	for i := range 10 {
		  		wg.Go(func() {
		  			switch {
		  			case i == 0:
		  				f(i, c1) // Zero uses c1
		  			case i%2 == 0:
		  				f(i, c2) // Even numbers use c2
		  			default:
		  				f(i, c3) // Odd numbers use c3
		  			}
		  		})
		  	}
		  	wg.Wait()
		  }
		  
		  func f(i int, c context.Context) {
		  	for {
		  		time.Sleep(time.Second)
		  		select {
		  		case <-c.Done():
		  			fmt.Printf("done %d\terr=%v\n", i, c.Err())
		  		default:
		  			fmt.Printf("work %d\terr=%v\n", i, c.Err())
		  		}
		  	}
		  }
		  
		  ```