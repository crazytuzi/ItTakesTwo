class UCharacterAirJumpsComponent : UActorComponent
{
	const int ChargesMax = 1;
	int JumpCharges = 1;
	int DashCharges = 1;

	// Storage for when the jump activated. Used for blocking air comp after jump as recently been pressed
	float JumpActivationRealTime = 0.f;
	// The length of the cooldown (and subsequent buffer) between the jump and the next air jump
	const float PostJumpDoubleJumpCooldown = 0.175f;

	// Will return true if you have enough air jump charges, and will consume a charge
	bool ConsumeJump()
	{
		if (JumpCharges > 0)
		{
			JumpCharges -= 1;
			return true;
		}
		else
			return false;
	}

	// Will return true if you have enough air dash charges, and will consume a charge
	bool ConsumeDash()
	{
		if (DashCharges > 0)
		{
			DashCharges -= 1;
			return true;
		}
		else
			return false;
	}

	// Will return 0 if there were no charges, 1 if only 1 air move had charges, 2 if both had charges
	// Will consume both charges (if possible)
	int ConsumeJumpAndDash()
	{
		int ChargesUsed = 0;

		if (JumpCharges > 0)
		{
			JumpCharges -= 1;
			ChargesUsed++;
		}

		if (DashCharges > 0)
		{
			DashCharges -= 1;
			ChargesUsed++;
		}
		
		return ChargesUsed;
	}

	// Resets only the air jump
	void ResetJump()
	{
		JumpCharges = ChargesMax;
	}

	// Resets only the air dash
	void ResetDash()
	{
		DashCharges = ChargesMax;
	}

	// Resets both the air jump and air dash
	void ResetJumpAndDash(bool bResetJump = true, bool bResetDash = true)
	{
		if (bResetJump)
			JumpCharges = ChargesMax;

		if (bResetDash)
			DashCharges = ChargesMax;
	}

	bool CanJump() const
	{
		return JumpCharges > 0;
	}

	bool CanDash() const
	{
		return DashCharges > 0;
	}
}