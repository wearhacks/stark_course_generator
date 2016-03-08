# Stark Labs Course Generator

This is the module with which content creators can generate tutorials (or full-blown courses) 
that will be hosted at Stark Labs.

Read The Fine Manual below to learn how to use it!


## Background

A course in Stark Labs consists of a series of **Chapters** which themselves are made up of **Cards**. 

Each chapter is supposed to have a specific learning objective. The cards employ a variety of means to meet those objectives:
* Plain instructions/textual explanations (which have to be kept short otherwise peolpe just get distracted/discouraged).
* Mini-problems in the form of code snippets that students have to fill in - CodeAcademy style!
* Media, such as GIF images showing what an outcome should look like (e.g. a LED blinking on an Arduino).

The course creation happens through a sequence of commands through which you create the content. The Stark generator is 
essentially a Ruby script which you should have installed as a gem. The root of your Stark installation contains a "courses" 
directory under which you can create your courses. You can look at the "Blink" course as an example of what your resulting
course would look like.

**TL;DR:** Your objective is to create a **Course** which consists of **Chapters** which in turn is made up of **Cards**. 
You do that through a combination of standard Unix and Stark-specific commands.


## Functions

Legend: **required** parameters are in **bold text** while *optional* parameters are in *italics*.

### Usage (a.k.a. I have no idea what I'm doing)

This is the default command so either 
```shell
$ stark
```
or

```shell
$ stark help
```

will do.

Like this guide, it will act almost like a man page.

### Course Generation
#### Bootstrap
Whenever you want to start a new course you can choose a template based on your target platform (although for the time being we only support
**Arduino** (preferably the Uno model) - which is the default value for the *platform* parameter). You scaffold a course structure like this:

```shell
$ stark init # same as "stark init arduino"
Give your course a name: Blink
Creating Blink based on the Arduino template...
Done!
$ ls Blink/
1 - Introduction To Arduino Programming
$
$ ls Blink/1\ -\ Introduction\ To\ Arduino\ Programming/
1 - Connect Your Arduino
2 - Make Your Arduino Blink!
3 - Connection Demonstration
4 - Check Your Connectivity
```

You can delete the (only) chapter (part of the Arduino project template) that is put there, unless of course you want to look at the structure
to understand what is going on.

On the following sections we will explain the purpose of the objects used by the platform and the conventions we adopt. You can already see some 
if you look at the Blinky files.

#### Chapters

To create chapters, you simply do inside a course's directory:
```shell
$ mkdir "1 - Introduction To Arduino Programming"
```

So the notion of a Chapter is simply a subdirectory under the directory where you bootstrapped the course. Other than that, there is 
nothing special about chapters

##### Restrictions
* The name of the chapter directories has to follow that format (number, whitespace, dash, whitespace, then the title) otherwise your course won't pass validation.
In other words (for the RegEx-savvy), it has to match [0-9]+\s\-\s[A-z|\s|0-9]+. As of now, you are responsible for ensuring your numbering is consistent and that 
your titles make sense. In the future we might employ better checking ourselves to make that easy for you.
* Currently you can have up to <b>10</b> chapters.


#### Course Content
If you have a course under ./Blink then you can do this:

<pre>
$ stark (add | remove) "Blink/1 - Introduction To Arduino Programming/"
</pre>

Note that you should only be able to create cards in a chapter.

When creating a card, you have to specify what type of card you want 
(Instruction, Code, Media, Question) as well as other applicable details. 
This will be done in a Q&A fashion depending on each card's structure:

<pre>
$ What type of card do you want? 
  [1] Instruction
  [2] Code
  [3] Media
  [4] Question
> 1
Name your card (follow this format: "1 - My Card" (without the quotes)): 2 - More Instructions
Done! Your card 
</pre>

##### Restrictions
* You can have a maximum of 10 cards per chapter.

#### Editing Content
Simple - once you are done creating the card you can go edit it. Each card is represented by an XML file. As much as
we all hate XML because it's verbose, we can at least validate easily whether the course you have created follows the
structure that every course should follow.

##### Instructions
Simple enough - this is where you illustrate a topic.
You can optionally provide a media file with your instruction card to illustrate something:

```XML
<card title="1 - Connect Your Arduino">
    <instruction>
        Download your Arduino drivers etc. etc.
    </instruction>
</card>
```

##### Code
You have to supply 3 files:

1. The file that will contain the template the student will be presented with during the exercise.
   You should put insturctions in the comments.
2. The test that validates a solution.
3. The file that contains a solution which can pass the supplied test.

```XML
<card title="2 - Make your Arduino blink!">
    <code template="blink_template.ino" solution="blink_solution.ino" test="blink_test.cc" difficulty="easy"/>
</card>
```

##### Media
Use this card type when you just need to provide a picture for demonstration.
We only support image files (for the time being at least). All media files are 
stored under the "media" directory (under the course's root) in case they are 
brought up multiple times throughout a course.

```XML
<card title="3 - Connection Demonstration">
    <media src="../media/arduino-blink.gif" />
</card>
```

##### Questions
The purpose of questions is to check students' understanding. They follow a multiple choice format. 
You have to supply 2-4 answer options.

Note that you have to specify the correct answer as the first one using the specified tag
(FYI this is due to a limitation in XSD 1.0, combined with the fact that we have to check 
the number of supplied answers and the fact that XSD 1.1.-enabled libraries are not common at all).
Do not worry about the order of the answers - we will mangle them so that the correct answer
is not always the first option. 

The specified difficulty can be set to one of "easy", "medium", "hard".
You can optionally supply a media file (e.g. to illustrate what the result should look like).

```XML
<card title="4 - Check your connectivity">
    <question q="Is your LED blinking?" difficulty="easy">
        <correctAnswer>Yes</correctAnswer>
        <answerOption>No</answerOption>
    </question>
    <media src="../media/arduino-blink.gif" />
</card>
```

### List Course Contents
<pre>
stark list <b>path/to/course/root</b>
</pre>
Shows the course content for the given course (as a file tree, with relevant information for each card).

### Run Your Tests
You add tests in test files that come with your code cards. The files are generated when you create the card.
For Arduinos, tests are based on arduino-mock (which is relies on Google Test, so if you are a seasoned C++ programmer,
you should find this easy to get used to. Google Test has an excellent guide here:

https://github.com/google/googletest/blob/master/googlemock/docs/ForDummies.md

You can also look at this example project to get an idea about how the API works:

https://github.com/ikeyasu/arduino-gmock-sample

... as well as the Blink project that you get if you bootstrap an Arduino project yourself. The code there is extremely 
simple but it is representative of how the framework works.

When you're all done and want to run all your tests:

<pre>
stark test <b>path/to/course/root</b>
</pre>

You should get feedback about compilation errors and failures against tests.

### Course Validation
<pre>
stark validate <b>path/to/course/root</b>
</pre>

This validates the course's structure against the Stark schema - only courses that comply with the given structure
can be pushed to the platform. This entails:
- Passing XSD validation: ensuring that you did not do anything out of the norm with the XML of each card
- Providing a sample solution and tests for each card (against which students' solutions will be checked).

### Course Publication
<pre>
stark push <b>path/to/course/root</b>
</pre>

This assembles, validates and publishes the course content to a Stark Labs remote repository. 
If there is any mishap during this process (e.g. supplied code does not pass the supplied 
unit tests or validation fails another step), the content will have to be reviewed before 
it is published.


## Summary

Ideally, your workflow would be along these lines:

1. You have a great idea about how people can learn by doing something on an Arduino (ideally any devide but for now let's just say it's an Arduino).
2. You work out the details - how you would explain things, formulate subproblems to be solved to reach a learning objective etc.
3. You do something along those lines:

``` shell
$ cd stark_course_generator
$ stark init my_awesome_course
$ cd courses/my_awesome_course
$ mkdir 1 - Some Chapter
$ stark add "1 - Some Chapter"

... 
# add cards, work out code, tests etc.

$ stark validate my_awesome_course

# Oh noes! Something was wrong
# (Fixing...)
# Great, finally done. Let's share the magic with everyone!

$ stark push Blink
``` 
Done! Watch out for feedback from the platform notifying you if server-side processing was OK.


## Recommendations

* The examples presented above might look like they need a lot of typing effort but if you have tab completion it should be a breeze.
* It might be worth aliasing the card creation commands to speed up your workflow.
* Generally it's a bad idea to mess with file names once you have generated them. You can do it of course but it is not recommended.
