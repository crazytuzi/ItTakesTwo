#Button Mash

The button mash system is broken up into 3 major parts

##ButtonMashHandleBase
The handle is an object returned when you start a button mash.
The handle is your interface into what the system is doing. MashRate, for example, is retrieved from the handle. You should never receive a reference to the Component or Capability, all data and functionality should be funneled through the handle.

##ButtonMashComponent
The component handles the basic math for calculating the mash rate. The component also updates the mash-rate on the handle.

##ButtonMashCapability
The capability is responsible for the functionality of the ButtonMash, and updating specific data for specific ButtonMashes (see ButtonMashProgress.as)

To bind all these things together, we define **static functions** for our specific button mash. (Look in ButtonMashDefault.as for an example how this is structured). There are some helper static functions deeper in the system (Check ButtonMashStatics.as); these are **not** to be used by *users* of the system, rather they should be used when designing a new type of button mash to hook into the system.

To start button mashes, use the static functions related to that type (StartButtonMashDefaultAttachTo, StartButtonMashProgressAttachTo etc.). For more help, talk to the coder/designer who made that specific button mash.