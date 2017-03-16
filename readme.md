
This work flow engine is a lightweight request routing tool. In our application it encapsulates our business
processes. Architecturally it serves as part of the web middle-ware. As middle-ware it handles calling the
proper high level functions for a given HTTP request. We separate web UI based workflow from fundamental
business (policy) issues, rather than conflating the two problems.

In this sense, the the workflow engine handles the application decision making logic in the front
controller. (Specifically, in the server-side front controller since we have a separate browser UI
controller.)

It is important to remember that nearly all aspects of the current design proposal involve lightweight
solutions to typical problems. Rather than a comprehensive framework, we have chosen to use a select set of
off the shelf software modules to construct a framework suitable to our needs. 

We have an existing workflow engine which is a tiny piece of code, but if we imagine a situation where we
didn't already have a workflow engine, and we knew nothing about them then it would be easier to initially implement a
small web site with the page controller architecture. As a small site grows in number of web pages and
internal complexity, page controller becomes increasingly difficult to maintain.

Comparison of page controller and front controller, good text but image links are broken:

http://www.uchithar.net/2010/03/page-vs-front-controller.html

Wikipedia on front controller (no page controller in the Wikipedia):

https://en.wikipedia.org/wiki/Front_Controller_pattern

Microsoft notes in their docs about page controller, that code reuse is managed by creating a BaseController
class to handle code common to the several page controller scripts. Microsoft also notes that as a web
application becomes more complex it requires additional helper classes or moving to the front controller pattern.

https://msdn.microsoft.com/en-US/library/Ff649595.aspx

In his comparison (URL above), Uchitha Ranasinghe, lists a number of aspects. The table below examines those
in the context of the workflow engine as the implementation of a front controller (remember: server resident
front controller).

Let us analyze the 2 methods with respect to several aspects, using Uchitha Ranasinghe's table (simplified)
where the workflow engine is the key component of a front controller:

| Criteria                              | Page Controller        | Front Controller         | Workflow Engine          |
|---------------------------------------+------------------------+--------------------------+--------------------------|
| Complexity / Ease of Implementation   | Lower                  | Higher                   | Low                      |
| Code Duplication / Code quality       | Moderate, grows        | Low                      | Low                      |
| Testability                           | Low                    | Higher                   | Very high                |
| Adaptability/Flexibility              | Lower, adds complexity | Highly configurable      | Very flexible            |
| Performance                           | Good                   | Can be slower            | Good, minimal overhead   |
| Thread Safety                         | Lower                  | Higher                   | Higher                   |
| Work distriubution and responsibility | Easier, depends        | Harder, has dependencies | Harder, has dependencies |

Line by line:

1. Complexity is very low for page controller, especially when the web application has less than a dozen
pages. As front controllers go, the workflow engine is very easy to implement. The entire engine is only a
couple of pages of code. The intellectual logic of the workflow engine is not as direct as page controller.

1. As the project grows in size, page controller bogs down with additional complexity, and more burden on the
programmers to keep the application well structured.

1. The workflow engine can be "proved" in several senses of guaranteed execution. All of these technologies can
be tested with normal testing procedures (automated and otherwise). It is fairly easy to automatically build a
graphical representation of the workflow. This is unlikely or impossible with a workflow implemented purely in
code.

1. Page controller adapts well enough on a small scale, but as the application complexity increases, page
controller is (one again) either going to explode, or requires the programmers to work hard to impose viable
structure.

1. Page controller performs well, and a workflow engine front controller is similar. A traditional front
controller has to be carefully constructed and maintained. High throughput probably doesn't apply to SNAC, but
in applying a load balancer to the page controller pattern is more difficult.

1. Thread safety doesn't apply to SNAC, but page controller is weak in this area.

1. Work distribution is easier with page controller to the extent that the controllers are separate. As an
application becomes more complex, page controller will probably gain a base controller class (if it didn't
have one from the outset). This and other efforts at minizing code duplication mean that all all options
eventually become fairly similar in terms of programmer work distribution. It is theoretically possible for
non-programmers to edit the workflow, but in practice the workflow maintenance is likely to be a
programmer/admin team (paired programming) task. I've showed the workflow state table to a non programmer
(Sarah) who immediately understood its purpose and considered it legible.

Additional links:

https://en.wikipedia.org/wiki/Mediator_pattern

A SO post with page controller defined:

http://stackoverflow.com/questions/4298037/what-is-the-page-controller-pattern-exactly

http://www.phpwact.org/pattern/page_controller

https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller

https://en.wikipedia.org/wiki/Business_logic

https://en.wikipedia.org/wiki/Workflow_engine

https://en.wikipedia.org/wiki/Workflow_technology

Apparently a simply number guessing game, in Windows Worflow Foundation:

https://code.msdn.microsoft.com/Windows-Workflow-164557c3/sourcecode?fileId=23474&pathId=1102925042

An intro to workflows, and blurb about WF4, brief examples also:

https://msdn.microsoft.com/en-us/library/ee342461.aspx

.NET simple state machine, more complex that our workflow engine, but simpler than full enterprise solutions:

https://github.com/nblumhardt/stateless



Current Architecture of the Workflow Engine
---

Underlying the workflow engine is a state machine. We "program" that state machine via a state table of
sorts. This table has names of steps within the workflow (states), and functions to preform the work. Each
row of the table is the name of a state, an optional test, an optional function, and the next state to execute
if the current state's test is "true". The machine starts with the "login" state, and runs until it hits a "wait"
function. It always starts/re-starts at the login state, thus validating that users are authenticated. This
also deals with the stateless nature of http and the ability of people (and hackers) to arbitrarily send input
to the web server.

The workflow engine has been carefully designed to capture the flow of work and nothing else. (See
"separation of concerns" below.) This technology has a long track record of success, although it is
underutilized.


Currently we are using demo_v3.pl and states_v3.pl which are using what we call the "4 column state
table". The 4 columns are: 

1. starting (current) state

1. Boolean tests (if tests), a blank defaults to "true"

1. dispatched functions that do work, a blank defaults to nothing aka "no-op"

1. the next state 

Internal functions (actually more of a pseudo-functions) are "jump", "return", and "wait". Jump pushes the
next state onto a stack, and jumps to the state named in its argument. The return function pops the stack and
goes to the named state. Function wait simply stops the engine. Jump is the only function that takes an
argument.

In a web environment it is reasonable to start the state machine from scratch for every HTTP request. There
are two reasons for this: 

1. The user might edit the URL and simply go to a different page in the web site without using any of the user
interface buttons or widgets.

1. Due to concerns both for the logic of the web interface and security, the server must sanity check all
information from the user. The simple way to do that is simply start at a base state for the workflow
process. This 'start from scratch every time' is fairly typical of state machine use.


What are tests?
---

The tests in column 2 are simply names of API functions that return true/false (Boolean) values. If the test
returns true then the state will transition to the next state which is the 4th column. The API will have a
large number of tests. Test functions are typically very small, often only a single line, and nearly always
less than 10 lines of code. The concerns of tests are very focused. The tests are run against the environment
of the application. Data includes all the communication from the user, as well as all data accessible to the
user on the server. The programmers should not do anything in a test except test values and return a
Boolean. Doing other work in a test amounts to a side effect, and that is deplorable coding style because it
causes horrible bugs.


What are functions?
---

The functions in column 3 are the actual work of the API. The entire purpose of the web application is to run
these functions in the order specified by the workflow states. The functions take no arguments from the state
machine, but instead gather their requisite data from the server environment. That environment is the CGI from
HTTP requests, Apache httpd cookies, and the server database. A function such as "unlock" looks for the
document current being used and unlocks it. There are many functions, each with a small area of concern. It is
left to the discretion of the programmers to separate functions into an appropriate level of
granularity. 

There might be a function that unlocks, sends email to the editor, emails the moderator, and
notifies watchers. However, if the technical requirements specify workflows with out a moderator, then such a
comprehensive function is not sensible. As the web application evolves, we can expect some functions to be
broken into smaller, separate functions and new workflow states added. 


What happens if all the tests fail?
---

All the tests may fail for a variety of reasons. The workflow design may have an oversight. The web
application will be attacked by hostile parties. When there are no true tests for the current state, the
machine goes to the reset state. Typically reset involves logging out the specified user, and drawing the home
page.


Can the state table be analyzed?
---

Yes. One of the best properties of state machines of this simple design is that the state table can be
computationally analyzed and sanity checked for a variety of morbid traits. This analysis is definitive,
unlike such analysis applied to fully functional programming languages. 

Beyond automated analysis, we have the workflow demonstrator that allows us to choose a state, and answer
yes/no for the tests and get feedback about which functions will run, and where we will go in the
workflow. This is a fully interactive demo and a handy way to interact with the work flow. 

It is possible to create a diagram of the workflow, but an actual implementation of that visualization has not
been explored.


Why doesn't this workflow engine have variables?
---

Adding more features to make the workflow engine more of a "programming language" is not necessary, and
precludes analysis of the state table. In common with technologies such as SQL, the limited nature of this
state machine guarantees that it will perform in reasonable ways. In other words, it won't be buggy. In fact,
bugs will be very rare, easy to detect, and easy to fix. As opposed to bugs, we have more of the quality of,
"Hey, this isn't what I intended to do" and that is easily rectified. Additionally, since the workflow is
reduced to a easy to understand representation, non-programmer stake holders can more easily interact with and
give feedback about the workflow. 

The lack of high-level programming language features such as variable and loops is not much of a
limitation. The tests and functions contain the complex code that implements the nitty-gritty of the
application. We have "separation of concerns", and the concern of the workflow engine is limited only to work
flow. Again akin to SQL, this is "what not how". We see what will happen, but we don't want to know how it
will happen.

There are other workflow solutions that use a full-featured programming language specific to that work flow
solution. The workflow specification is essentially application code, and is just as difficult to understand
as if it had been written in PHP, Perl, or Java. 


Is the internal code of the workflow engine complex?
---

No, it is very simple. See demo_v3.pl. The subroutine main() is the central logic, and comprises just over 100
lines of code. The state machine is very fast and performs well. It imposes almost no load on the web
application, in part because its only job is to dispatch the functions that do the real work.


Are there other implementations of this workflow engine?
---

Yes. The original historical precedent fewer columns and some what different transitions. The end result was
identical, but the state table was a bit harder to interpret for non-programmers. It was invented by Kelton
Flinn and used to determine the workflow (behavior) of computer run non-player-characters in the game "The
Island of Kesmai". The sheriff workflow was to patrol town. Shopkeeper work flow was to buy and sell. The
dragon's workflow was to guard its hoard of gold and eat players.

There are at least two other more recent implementations, one of which combines test/function resulting in a 3
column table.
