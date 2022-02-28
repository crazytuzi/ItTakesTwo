Double Pull Animation Parameters:

Feature tag requested is 'Double Pull' for both interacting players and the pulled actor.

Available on players and pulled actor:
- DoublePullIsMoving (bool): Whether the double pull is moving because it is being pulled by players.
- Locomotion Request has delta and direction for how the pull is actually moving.

Available on players only:
- DoublePullInputMagnitude (float): How much input the player is giving to pull.
- DoublePullBackwardsPull (float): How much input the player is giving to pull backwards.
- DoublePullHorizontalPull (float): How much input the player is giving to pull sideways.

Available on pulled actor only:
- DoublePullCodyInteracting (bool): Whether Cody is interacting with the double pull right now.
- DoublePullMayInteracting (bool): Whether May is interacting with the double pull right now.
- DoublePullGoingBack (bool): Whether the double pull is currently automatically going backwards on the spline.

- DoublePullIsAtStart (bool): Whether the pulled actor is at the start of the spline right now.
     Note: Only available if the double pull has a DoublePullGoBack capability.