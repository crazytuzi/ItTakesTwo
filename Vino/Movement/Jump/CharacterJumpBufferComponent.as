
class UCharacterJumpBufferComponent : UActorComponent
{
	float RegisteredJumpTime = -1.f;
	float TimeWindow = 0.f;

	void RegisterJump(float _TimeWindow = 0.3f)
	{
		RegisteredJumpTime = Time::GetRealTimeSeconds();
		TimeWindow = _TimeWindow;
	}

	void ConsumeJump()
	{
		RegisteredJumpTime = -1.f;
	}

	bool IsJumpBuffered()
	{
		if (RegisteredJumpTime < 0.f)
			return false;

		const float CurrentTime = Time::GetRealTimeSeconds();
		const float Dif = CurrentTime - RegisteredJumpTime;

		return Dif < TimeWindow;
	}
}
