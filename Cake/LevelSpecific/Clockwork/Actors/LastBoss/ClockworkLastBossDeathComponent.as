class UClockworkLastBossDeathComponent : UActorComponent
{
	float FallHeightToDeath = 2000.f;

	void SetNewFallHeightToDeath(float NewFallHeight)
	{
		FallHeightToDeath = NewFallHeight;
	}
}