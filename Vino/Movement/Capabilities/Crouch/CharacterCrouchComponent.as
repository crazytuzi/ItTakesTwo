

class UCharacterCrouchComponent : UActorComponent
{
	bool bForceCrouching = false;
	int ForceCrouchScore = 0;

	bool bForceGrounded = false;

	void ForceGrounded()
	{
		bForceGrounded = true;
	}

	void UnforceGrounded()
	{
		bForceGrounded = false;
	}

	bool IsGroundedForce() const
	{
		return bForceGrounded;
	}

	bool IsCrouchingForced() const
	{
		if (ForceCrouchScore > 0)
			return true;

		return bForceCrouching;
	}

	void ForceCrouch()
	{
		bForceCrouching = true;
	}

	void ResetForceCrouch()
	{
		bForceCrouching = false;
	}

	void EnteredForceCrouchVolume()
	{
		ForceCrouchScore += 1;
	}

	void LeftForceCrouchVolume()
	{
		ForceCrouchScore -= 1;
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		bForceGrounded = false;
	}
	
}
