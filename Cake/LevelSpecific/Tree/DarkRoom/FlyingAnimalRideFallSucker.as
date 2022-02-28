import Peanuts.Spline.SplineComponent;
import Vino.Movement.Components.MovementComponent;
class AFlyingAnimalRideFallSucker : AHazeActor
{

	UPROPERTY(DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent SuckSpline;


	default SetActorTickEnabled(false);

	UFUNCTION()
	void StartSuckingPlayers()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PrintToScreen("IsSucking");

		for (auto Player : Game::Players)
		{
			//Establish values
			FVector ClosestSplinePoint = SuckSpline.FindLocationClosestToWorldLocation(Player.GetActorLocation(), ESplineCoordinateSpace::World);
			FVector Direction = ClosestSplinePoint - Player.GetActorLocation();
			float DistanceToClosestLocation = Direction.Size();
			float Multiplier = FMath::GetMappedRangeValueClamped(FVector2D(10000.f, 3000.f), FVector2D(2.f, 0.5f), DistanceToClosestLocation);
		
			//Get normalized direction without Z
			Direction.Z = 0.f;
			Direction.Normalize();
			
			auto PlayerMoveComp = UHazeMovementComponent::Get(Player);

			PlayerMoveComp.AddImpulse(Direction * (5000.f * Multiplier) * DeltaTime);

			float HeightDistanceBetweenPlayers = Player.GetActorLocation().Z - Player.OtherPlayer.GetActorLocation().Z;

			float ZMultiplier = FMath::GetMappedRangeValueClamped(FVector2D(10000.f, 300.f), FVector2D(1.f, 0.f), HeightDistanceBetweenPlayers);

			if (HeightDistanceBetweenPlayers > 0.f)
			{
				PlayerMoveComp.AddImpulse(FVector::UpVector * (-5000.f * ZMultiplier) * DeltaTime);
			}
		}
		


	}


}