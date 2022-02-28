enum ELarvaBasketScoreType
{
	Low,
	Medium,
	High,
}

namespace LarvaBasket
{
	const float GameDuration = 60.f;

	const float JumpGravity = 4800.f;
	const float JumpImpulse = 3000.f;
	const float JumpHoldGravityScale = 0.8f;
	const float JumpHoldTime = 0.5f;

	const float ThrowHoverGravity = 400.f;
	const float ThrowHoverDuration = 0.3f;

	const float ThrowTimeMin = 0.14f;
	const float ThrowTimeMax = 0.5f;
	const FVector ThrowOffset = FVector(100.f, 0.f, 150.f);
	const float ThrowChargeExponent = 1.1f;

	const float BallGravity = 5900.f;
	const float BallBounciness = 0.6f;
	const float BallBounceUpImpulse = 350.f;
	const float BallSyncFrequency = 10.f;
	const float BallTotalLifeDuration = 3.f;
	const float BallIgnoreHitDuration = 0.2f;

	const float CylinderBaseSpeed = 15.f;

	// X = Horizontal, Y = Vertical
	const FVector BallImpulseGround = FVector(2450.f, 0.f, 2550.f);
	const FVector BallImpulseAir_Min = FVector(2450.f, 0.f, 2250.f);
	const FVector BallImpulseAir_Max = FVector(2450.f, 0.f, 3180.f);

	const float HoopRailSpeed = 280.f;
	const float HoopSpawnerDelay = 2.4f;

	const TArray<int> ScoreBaseProportions = InitScoreProportions();

	const int HoopPoolSize = 10;
	const float HoopSpawnSpacing = 600.f;

	TArray<int> InitScoreProportions()
	{
		TArray<int> Proportions;
		Proportions.Add(6); // Low
		Proportions.Add(4); // Medium
		Proportions.Add(1); // High

		return Proportions;
	}
}

UFUNCTION(BlueprintPure, Category = "Minigame|LarvaBasket")
int LarvaBasketGetScoreForType(ELarvaBasketScoreType Type)
{
	switch(Type)
	{
		case ELarvaBasketScoreType::Low: return 1;
		case ELarvaBasketScoreType::Medium: return 3;
		case ELarvaBasketScoreType::High: return 5;
	}

	return 0;
}

float LarvaBasketGetHoopSizeForType(ELarvaBasketScoreType Type)
{
	switch(Type)
	{
		case ELarvaBasketScoreType::Low: return 1.f;
		case ELarvaBasketScoreType::Medium: return 0.8f;
		case ELarvaBasketScoreType::High: return 0.6f;
	}

	return 1.f;
}