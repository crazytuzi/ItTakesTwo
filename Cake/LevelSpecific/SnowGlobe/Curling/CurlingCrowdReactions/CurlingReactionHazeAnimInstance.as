class UCurlingReactionHazeAnimInstance : UHazeAnimInstanceBase
{
	UPROPERTY()
	float TalkingMinTime = 5.f;
	
	UPROPERTY()
	float TalkingMaxTime = 10.f;
	
	UPROPERTY()
	float TalkingTime;

	UPROPERTY()
	float MinPlayRate = 0.7f;
	
	UPROPERTY()
	float MaxPlayRate = 1.f;
	
	UPROPERTY()
	float IdlePlayRate;

	UFUNCTION()
	void SetNewTalkingTime()
	{
		TalkingTime = FMath::RandRange(TalkingMinTime, TalkingMaxTime);
	}

	UFUNCTION()
	void SetIdlePlayRate()
	{
		IdlePlayRate = FMath::RandRange(MinPlayRate, MaxPlayRate);
	}

	UFUNCTION()
	void SetTalkingTime(float DeltaTime)
	{
		TalkingTime -= DeltaTime;
	}
}