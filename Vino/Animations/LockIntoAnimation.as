/* Disable the player's capabilities that they should not be able to use when locked into an animation. */
UFUNCTION(Category = "Animation")
void LockIntoAnimation(AHazePlayerCharacter Player, UObject LockingObject)
{
    Player.BlockCapabilities(n"GameplayAction", LockingObject);
    Player.BlockCapabilities(n"Interaction", LockingObject);
    Player.BlockCapabilities(n"Movement", LockingObject);
    Player.BlockCapabilities(n"Falling", LockingObject);
}

/* Re-enable any of the player's capabilities that were blocked by LockIntoAnimation. */
UFUNCTION(Category = "Animation")
void UnlockFromAnimation(AHazePlayerCharacter Player, UObject LockingObject)
{
    Player.UnblockCapabilities(n"GameplayAction", LockingObject);
    Player.UnblockCapabilities(n"Interaction", LockingObject);
    Player.UnblockCapabilities(n"Movement", LockingObject);
    Player.UnblockCapabilities(n"Falling", LockingObject);
}