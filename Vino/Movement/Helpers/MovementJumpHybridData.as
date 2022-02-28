import Vino.Movement.Components.MovementComponent;

struct FMovementCharacterJumpHybridData
{
    void Reset()
    {
		CurrentJumpTime = 0.f;
		VerticalVelocity = 0.f;

		AscentTime = 0.f;
		AscentPeakHeight = 0.f;
    }

	void StartJump(float Impulse)
	{
		Reset();
		VerticalVelocity = Impulse;
	}

	float GetSpeed() const
	{
		return VerticalVelocity;
	}

	FVector CalculateJumpVelocity(float DeltaTime, bool bIsHoldingJump, UHazeMovementComponent MoveComp)
	{
		return CalculateJumpVelocity(DeltaTime, bIsHoldingJump, MoveComp.MaxFallSpeed, -MoveComp.GravityMagnitude * MoveComp.JumpSettings.JumpGravityScale, MoveComp.WorldUp);
	}
	
    FVector CalculateJumpVelocity(float DeltaTime, bool bIsHoldingJump, float TerminalVelocity, float Gravity, FVector WorldUp)
	{
		float NextJumpTime = CurrentJumpTime + DeltaTime;

		// We dont care about the direction of gravity, just the magnitude
		float CurrentGravity = Gravity;

		int VelocitySign = FMath::Sign(VerticalVelocity);
		if (VelocitySign > 0)
		{
			// When moving upwards, we scale gravity to achieve higher jumping
			// when holding the jump button for a short time
			if (bIsHoldingJump && CurrentJumpTime < MaxHoldTime)
			{
				// Framerate independency - Account for overshooting the mark on lower framerates
				if (NextJumpTime > MaxHoldTime)
				{
					float Overshoot = NextJumpTime - MaxHoldTime;
					float PercentOvershoot = 1.0 - (Overshoot / DeltaTime);

					CurrentGravity *= HoldGravityScale * PercentOvershoot;
				}
				else
					CurrentGravity *= HoldGravityScale;
			}

			// Record height and time to reach it
			AscentTime += DeltaTime;
			AscentPeakHeight += VerticalVelocity * DeltaTime;

			AscentGravity = Gravity;
		}
		else if(AscentTime > 0.f)
		{
			// On the way down, calculate the gravity needed so that the ascent-time
			// exactly matches the descent-time
			CurrentGravity = -(2.f * AscentPeakHeight) / (AscentTime * AscentTime);

			// Make sure we take gravity change into account during the descent
			CurrentGravity = CurrentGravity * (Gravity / AscentGravity);
		}

		CurrentJumpTime = NextJumpTime;

		// Update velocity
		VerticalVelocity += CurrentGravity * DeltaTime;
		return WorldUp * VerticalVelocity;
	}

	// The value that scales gravity when holding the jump button
	private float HoldGravityScale = 0.15f;

	// Recording how long we've jumped
    private float CurrentJumpTime = 0.f; 

	// How long we're allowed to hold the jump-button to gain height
	private float MaxHoldTime = 0.175f;

	// Values for tracking the curve, for making a symmetrical curve when descending
	private float AscentTime = 0.f;
	private float AscentPeakHeight = 0.f;

	// Out current velocity, we dont care about horizontal movement
	private float VerticalVelocity = 0.f;

	// Saved gravity during the ascent of the jump, used to calculate gravity multiplier when descending
	private float AscentGravity = 0.f;
};
