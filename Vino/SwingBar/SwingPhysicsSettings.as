struct FSwingPhysicsSettings
{
    /* -- Physics Settings -- */
    // Length of the simulated physics pendulum. Has no graphical effect, only affects the physics. 
    UPROPERTY(Category = "Pendulum")
    float PendulumLength = 200.f;
    // The highest angle that is achieved while swinging on the pendulum
    UPROPERTY(Category = "Pendulum")
    float MaximumSwingAngle = 0.5f * PI;
	// Minimum horizontal speed to gain when jumping off mostly vertical
    UPROPERTY(Category = "Jump Off")
    float JumpOffMinHorizontalSpeed = 1000.f;
	// Maximum horizontal speed to gain when jumping off mostly horizontal
    UPROPERTY(Category = "Jump Off")
    float JumpOffMaxHorizontalSpeed = 1100.f;
	// Minimum vertical speed to gain when jumping off from lowest position
    UPROPERTY(Category = "Jump Off")
    float JumpOffMinVerticalSpeed = 2200.f;
	// Maximum vertical speed to gain when jumping off from highest position
    UPROPERTY(Category = "Jump Off")
    float JumpOffMaxVerticalSpeed = 2500.f;
    // Amount to bend the jump off direction to auto-aim towards the next swixng
    UPROPERTY(Category = "Jump Off")
    float JumpOffAutoAimPercentage = 1.f;
    // Maximum distance to auto-aim at the next swing
    UPROPERTY(Category = "Jump Off")
    float JumpOffAutoAimMaxDistance = 900.f;
    // Maximum angle that our jump off would have to bend to consider auto aiming at a nail
    UPROPERTY(Category = "Jump Off")
    float JumpOffAutoAimMaxAngleBend = 0.5f * PI;
    // Grace period where we can jump off in the forward direction after already starting to swing backwards
    UPROPERTY(Category = "Jump Off")
    float JumpOffSwingDirectionGracePeriod = 0.3f;
    // Maximum angle offset from the horizontal plane that the nail can be before we disallow swinging from it
    UPROPERTY(Category = "Pendulum")
    float MaxVerticalAngleToAllowSwing = 0.2f * PI;
    // Maximum angle that the nail can be entered at
    UPROPERTY(Category = "Entry")
    float EntryMaxAngle = 0.1f * PI;
	// If our entry angle is less than this, we are allowed to control direction the swing enters at with stick input
    UPROPERTY(Category = "Entry")
    float EntryControllableDirectionAngle = 2.f * PI;
    // Multiplier to the speed we already swing at during the initial enter animation.
    UPROPERTY(Category = "Entry")
    float EntryAnimationSwingSpeedFactor = 0.1f;
	// Cooldown time before we're allowed to enter the same swing again
    UPROPERTY(Category = "Cooldown")
    float SameSwingCooldownTime = 1.f;
	// Cooldown time before we're allowed to enter any other swing after jumping off
    UPROPERTY(Category = "Cooldown")
    float AnySwingCooldownTime = 0.25f;
};