import Cake.LevelSpecific.Garden.LevelActors.Shrubbery.InfectedSprinkler;
import Vino.Checkpoints.Statics.DeathStatics;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.BeanstalkLeafPair;

class UInfectedSprinklerCapability: UHazeCapability
{
	default CapabilityTags.Add(n"InfectedSprinkler");
	default CapabilityDebugCategory = n"InfectedSprinkler";
	default TickGroup = ECapabilityTickGroups::GamePlay;

	AInfectedSprinkler Sprinkler;

	float MovementSpeed;

	float TimeLikeAlpha = 0.0f;
	
	bool bPlayedKilled = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Sprinkler = Cast<AInfectedSprinkler>(Owner);
		//MovementSpeed = Sprinkler.MovementSpeed;	
		Sprinkler.SprinklerMovementTimeLike.BindUpdate(this, n"UpdateSprinklerMovementTimeLike");
	}		
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Sprinkler.bActivated)
		{
			return EHazeNetworkActivation::DontActivate;
		}
        
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!Sprinkler.bActivated)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Sprinkler.SprinklerMovementTimeLike.PlayFromStart();
		Sprinkler.BoxCollider.OnComponentBeginOverlap.AddUFunction(this, n"BoxCollisionBeginOverlap");
		//Sprinkler.BoxCollider.OnComponentEndOverlap.AddUFunction(this, n"BoxCollisionEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Sprinkler.SprinklerMovementTimeLike.Stop();
		Sprinkler.BoxCollider.OnComponentBeginOverlap.Unbind(this, n"BoxCollisionBeginOverlap");
		//Sprinkler.BoxCollider.OnComponentEndOverlap.Unbind(this, n"BoxCollisionEndOverlap");
		Sprinkler.SprinklerEffect.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float SprinklerPitchRotation = FMath::Lerp(0.0f, Sprinkler.MaxPitch, TimeLikeAlpha);
		SprinklerPitchRotation = FMath::Clamp(SprinklerPitchRotation, -Sprinkler.MaxPitch, Sprinkler.MaxPitch);

		Sprinkler.RotationRoot.SetRelativeRotation(FRotator(SprinklerPitchRotation, Sprinkler.RotationRoot.RelativeRotation.Yaw, Sprinkler.RotationRoot.RelativeRotation.Roll));
	}


	UFUNCTION()
	void BoxCollisionBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		if(Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
			
			FHitResult OutHit;			
			TArray<AActor> ActorsToIgnore;

			FVector LineStartPosition = FVector(Player.ActorLocation.X, Player.ActorLocation.Y, Sprinkler.BoxCollider.WorldLocation.Z + Sprinkler.BoxCollider.BoxExtent.Z);
			FVector LineEndPosition = FVector(Player.ActorLocation.X, Player.ActorLocation.Y, Sprinkler.BoxCollider.WorldLocation.Z - Sprinkler.BoxCollider.BoxExtent.Z);

			System::LineTraceSingle(LineStartPosition, LineEndPosition, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::ForDuration, OutHit, true);
			if(OutHit.bBlockingHit)
			{
				if(Cast<ABeanstalkLeafPair>(OutHit.Actor) != nullptr)
				{
					return;
				}
				else
				{
					KillPlayer(Player, Sprinkler.DeathEffect);					
				}
			}
		}
	}

	// UFUNCTION(NotBlueprintCallable)
    // void BoxCollisionEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    // {
	// 	if(Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
	// 	{
	// 		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
			
	// 		FHitResult OutHit;			
	// 		TArray<AActor> ActorsToIgnore;

	// 		FVector LineStartPosition = FVector(Player.ActorLocation.X, Player.ActorLocation.Y, Sprinkler.BoxCollider.WorldLocation.Z + Sprinkler.BoxCollider.BoxExtent.Z);
	// 		FVector LineEndPosition = FVector(Player.ActorLocation.X, Player.ActorLocation.Y, Sprinkler.BoxCollider.WorldLocation.Z - Sprinkler.BoxCollider.BoxExtent.Z);

	// 		System::LineTraceSingle(LineStartPosition, LineEndPosition, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, OutHit, true);
	// 		if(OutHit.bBlockingHit)
	// 		{
	// 			if(Cast<ABeanstalkLeafPair>(OutHit.Actor) != nullptr)
	// 			{
	// 				return;
	// 			}
	// 			else
	// 			{
	// 				KillPlayer(Player, Sprinkler.DeathEffect);					
	// 			}
	// 		}
	// 	}
    // }


	UFUNCTION(NotBlueprintCallable)
	void UpdateSprinklerMovementTimeLike(float CurValue)
	{
		TimeLikeAlpha = FMath::Lerp(0.0f, 1.0f, CurValue);
	}
}