import Cake.LevelSpecific.Music.NightClub.DiscoBall;
import Cake.LevelSpecific.Music.NightClub.DiscoBallMovementSettings;
import Vino.PlayerHealth.PlayerHealthStatics;

class UCharacterDiscoBallMovementComponent : UActorComponent
{
	UPROPERTY()
	ANightclubDiscoBall DiscoBall;

	FDiscoBallMovementSettings MoveSettings;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathFX;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	FVector ConstrainMoveDelta(FVector WantedDelta, bool& bStartedOutOfBounds)
	{

		FVector DummyOrigin;
		FVector DummyBoxExtent;
		float SphereRadius = 0.f;
		
		System::GetComponentBounds(UStaticMeshComponent::Get(DiscoBall), DummyOrigin, DummyBoxExtent, SphereRadius);

		FTransform DiscoTransform = DiscoBall.ActorTransform;
		DiscoTransform.AddToTranslation(DiscoBall.ActorUpVector * SphereRadius);
		DiscoTransform.SetScale3D(FVector::OneVector);

		FVector OutputVector = DiscoTransform.Rotation.UnrotateVector(WantedDelta);
		
		FTransform PlayerLocalTransform = Owner.ActorTransform * DiscoTransform.Inverse();

		if (PlayerLocalTransform.Location.X > MoveSettings.AllowedDistanceFromCenter
			|| PlayerLocalTransform.Location.X < -MoveSettings.AllowedDistanceFromCenter
			|| PlayerLocalTransform.Location.Y > MoveSettings.AllowedDistanceFromCenter
			|| PlayerLocalTransform.Location.Y < -MoveSettings.AllowedDistanceFromCenter)
		{
			bStartedOutOfBounds = true;
		}

		FVector WantedLocation = PlayerLocalTransform.Location + PlayerLocalTransform.Rotation.UnrotateVector(WantedDelta);
		FVector OverShotAmount = WantedLocation - FVector(MoveSettings.AllowedDistanceFromCenter, MoveSettings.AllowedDistanceFromCenter, 0.f);

		float MaxNegative = MoveSettings.AllowedDistanceFromCenter * 2.f;

		if (OverShotAmount.X > 0.f)
			OutputVector.X = OutputVector.X - OverShotAmount.X;
		else if (OverShotAmount.X < -MaxNegative)
			OutputVector.X = OutputVector.X - (OverShotAmount.X + MaxNegative);

		if (OverShotAmount.Y > 0.f)
			OutputVector.Y = OutputVector.Y - OverShotAmount.Y;
		else if (OverShotAmount.Y < -MaxNegative)
			OutputVector.Y = OutputVector.Y - (OverShotAmount.Y + MaxNegative);

		
		OutputVector = OutputVector.ConstrainToPlane(DiscoBall.ActorUpVector);
		return DiscoTransform.Rotation.RotateVector(OutputVector);
	}

	float DistanceFromCenter()const
	{
		FVector BallToPlayerVector = Owner.ActorLocation - DiscoBall.ActorLocation;
		BallToPlayerVector.Z = 0.f;
		return BallToPlayerVector.Size();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//Check player position on ball for turning ball and send values to discoball
		FVector ConstrainedDiscoBallLoc = DiscoBall.GetActorLocation().ConstrainToDirection(DiscoBall.ActorRightVector);
		FVector ConstrainedPlayerLoc = Owner.GetActorLocation().ConstrainToDirection(DiscoBall.ActorRightVector);
		FVector ConstrainedPlayerToBall = ConstrainedDiscoBallLoc - ConstrainedPlayerLoc;
		float PlayerOffset = ConstrainedPlayerToBall.DotProduct(DiscoBall.ActorRightVector);
		
		if (Game::GetMay() == Owner)
		{
			DiscoBall.MayOffset = PlayerOffset;
		}
		else
		DiscoBall.CodyOffset = PlayerOffset;


	}
}