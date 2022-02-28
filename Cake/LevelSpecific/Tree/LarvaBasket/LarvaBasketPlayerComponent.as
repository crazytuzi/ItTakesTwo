import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketSettings;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketCage;
import Peanuts.Animation.Features.Garden.Basket.LocomotionFeatureLarvaBasket;
import Vino.Trajectory.TrajectoryStatics;

void LarvaBasketPlayerMissedBall(AHazePlayerCharacter Player, ALarvaBasketBall Ball)
{
	auto LarvaBasketComp = ULarvaBasketPlayerComponent::Get(Player);
	if (LarvaBasketComp == nullptr)
		return;

	LarvaBasketComp.OnMissBall();
}

class ULarvaBasketPlayerComponent : UActorComponent
{
	ALarvaBasketCage CurrentCage;
	ALarvaBasketBall HeldBall;

	UPROPERTY(Category = "Animation")
	TPerPlayer<ULocomotionFeatureLarvaBasket> Feature;

	bool bCanLeave = true;
	float AirTime = 0.f;

	FTransform GetThrowOrigin()
	{
		// Transform the throw impulse into world space
		FTransform ThrowTransform = Owner.ActorTransform;
		ThrowTransform.Scale3D = FVector::OneVector;

		FTransform OffsetTransform;
		OffsetTransform.Location = LarvaBasket::ThrowOffset;
		return OffsetTransform * ThrowTransform;
	}

	FVector GetAirThrowImpulse()
	{
		// Get the percentage height we're at
		float MaxJumpHeight = TrajectoryHighestPoint(
			FVector::ZeroVector,
			FVector(0.f, 0.f, LarvaBasket::JumpImpulse),
			LarvaBasket::JumpGravity).Z;

		float CurrentHeight = Owner.RootComponent.RelativeLocation.Z;
		float HeightPercent = CurrentHeight / MaxJumpHeight;

		// Local impulse
		FVector LocalImpulse = FMath::Lerp(LarvaBasket::BallImpulseAir_Min, LarvaBasket::BallImpulseAir_Max, HeightPercent);
		return GetThrowOrigin().TransformVector(LocalImpulse);
	}

	FVector GetGroundThrowImpulse()
	{
		// Local impulse
		FVector LocalImpulse = LarvaBasket::BallImpulseGround;
		return GetThrowOrigin().TransformVector(LocalImpulse);
	}

	UFUNCTION(BlueprintEvent)
	void OnThrowBall() {}

	UFUNCTION(BlueprintEvent)
	void OnMissBall() {}
}

void LarvaBasketEnterCage(AHazePlayerCharacter Player, ALarvaBasketCage Cage)
{
	auto PlayerComp = ULarvaBasketPlayerComponent::Get(Player);
	if (!devEnsure(PlayerComp != nullptr, "Player doesn't have a LarvaBasketPlayerComp. Is there a LarvaBasketVolume around?"))
		return;

	PlayerComp.CurrentCage = Cage;
}