// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticMoveableComponent;

// class MagneticPhysicsObjectCapability : UHazeCapability
// {

// 	default CapabilityTags.Add(n"MagnetCapability");

// 	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	
// 	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

// 	AActor Player;
//     UPrimitiveComponent MeshComponent;
// 	UMagneticComponent MagnetComponent;

// 	FVector StartLineBetweenplayers;
// 	FRotator StartOffsetWithObjectAndPlayers;
// 	float ForceReleaseTimer;
// 	float MaxVelocity = 7500;
// 	float NonInteractableTimer;
// 	bool CodyHasReleasedTriggerSinceInteracting = true;
// 	bool MayHasReleasedTriggerSinceInteracting  = true;


// 	float OnePlayerLetGoTimer = 0;


// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
//         MagnetComponent = UMagneticComponent::Get(Owner);
//         MeshComponent = Cast<UPrimitiveComponent>(Owner.RootComponent);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
//         if (MagnetComponent.GetInfluencerNum() > 0)
//         {
// 			if (IsInteractable)
// 			{
// 				return EHazeNetworkActivation::ActivateFromControl;
// 			}
            
// 			else
// 			{
// 				return EHazeNetworkActivation::DontActivate;
// 			}
//         }
        
//         else
//         {
//             return EHazeNetworkActivation::DontActivate;
//         }
// 	}

// 	bool GetIsInteractable() const
// 	{
// 		return (NonInteractableTimer == 0);
// 	}

//     FVector GetAttractionPosition()
//     {
//         FVector Position = Owner.GetActorLocation();

// 		if (MagnetComponent.ResultingForce > 0)
// 		{
// 			FVector DirToObj = Owner.GetActorLocation() - CenterPointOfAllPositiveInfluensers;
// 			DirToObj.Normalize();

// 			DirToObj *= GetExtents().Size() * 2;
// 			DirToObj.Z = 0;

// 			Position = CenterPointOfAllPositiveInfluensers + DirToObj + FVector::UpVector * GetExtents() * 1.1f;
// 		}

// 		else if (MagnetComponent.ResultingForce < 0)
// 		{
// 			FVector DirToObj = Owner.GetActorLocation() - CenterPointOfAllNegativeInfluensers;
// 			DirToObj.Normalize();

// 			DirToObj *= GetExtents().Size() * 2;
// 			DirToObj.Z = 0;
			
// 			Position = CenterPointOfAllNegativeInfluensers + DirToObj + FVector::UpVector * GetExtents() * 1.1f;
// 		}

// 		return Position;
//     }

// 	FVector GetCenterPointOfAllNegativeInfluensers()
// 	{
// 		FVector PosToReturn;
// 		int NumberOfInfluencers = 0;
// 		TArray<FMagnetInfluencer> Influencers;
// 		MagnetComponent.GetInfluencers(Influencers);
// 		for(const FMagnetInfluencer& Influenser : Influencers)
// 		{
// 			if (Influenser.NegativeForce > 0)
// 			{
// 				PosToReturn += Influenser.Instigator.GetActorLocation();
// 				NumberOfInfluencers++;
// 			}
// 		}

// 		if (NumberOfInfluencers != 0)
// 		{
// 			PosToReturn /= NumberOfInfluencers;
// 		}

// 		return PosToReturn;
// 	}

// 	FVector GetCenterPointOfAllPositiveInfluensers()
// 	{
// 		FVector PosToReturn;
// 		int NumberOfInfluencers = 0;
// 		TArray<FMagnetInfluencer> Influencers;
// 		MagnetComponent.GetInfluencers(Influencers);
// 		for(const FMagnetInfluencer& Influenser : Influencers)
// 		{
// 			if (Influenser.PositiveForce > 0)
// 			{
// 				PosToReturn += Influenser.Instigator.GetActorLocation();
// 				NumberOfInfluencers++;
// 			}
// 		}

// 		if (NumberOfInfluencers != 0)
// 		{
// 			PosToReturn /= NumberOfInfluencers;
// 		}

// 		return PosToReturn;
// 	}

// 	FVector GetAttractionDesiredDirection()
// 	{
// 		FVector Direction = GetAttractionPosition() - Owner.ActorLocation;

// 		return Direction;
// 	}

// 	bool ShouldForceReleasePlayer(float Deltatime)
// 	{
// 		float DistanceToAttractedPosition = Owner.GetActorLocation().Distance(AttractionPosition);

// 		if (DistanceToAttractedPosition > 300  && GetAttractionVelocity() > 0)
// 		{

// 			System::DrawDebugLine(Owner.GetActorLocation() , AttractionPosition);
// 			ForceReleaseTimer += Deltatime;
// 		}

// 		else
// 		{
// 			ForceReleaseTimer = 0;
// 		}

// 		if (ForceReleaseTimer > 0.75f)
// 		{
// 			return true;
// 		}

// 		else
// 		{
// 			return false;
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if (!IsInteractable)
// 		{
//             return EHazeNetworkDeactivation::DeactivateFromControl;
//         }


//         if (MagnetComponent.ResultingForce != 0)
//         {
//             return EHazeNetworkDeactivation::DontDeactivate;
//         }
        
//         else
//         {
//             return EHazeNetworkDeactivation::DeactivateFromControl;
//         }
// 	}

// 	void TrackAndSetRotation(float Delta)
// 	{
// 		MeshComponent.SetPhysicsAngularVelocityInDegrees(FVector::ZeroVector);
// 	}

// 	UFUNCTION()
// 	void ReleaseAttractedObject()
// 	{
// 		NonInteractableTimer = 1;

// 		if (MagnetComponent.ResultingForce < 0)
// 		{
// 			CodyHasReleasedTriggerSinceInteracting = false;
// 		}

// 		else 
// 		{
// 			MayHasReleasedTriggerSinceInteracting = false;
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		MeshComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
//         MeshComponent.SetEnableGravity(false);
// 		ForceReleaseTimer = 0;
// 		NonInteractableTimer = 0;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		MeshComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
// 		MeshComponent.SetEnableGravity(true);
// 		MeshComponent.SetAllPhysicsAngularVelocityInDegrees(FVector::ZeroVector, false);
// 		ForceReleaseTimer = 0;
// 	}

// 	void UpdateIsNonInteractable(float DeltaTime)
// 	{
// 		if (NonInteractableTimer > 0)
// 		{
// 			NonInteractableTimer -= DeltaTime;
// 		}

// 		else
// 		{
// 			NonInteractableTimer = 0;
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void PreTick(float DeltaTime)
// 	{
// 		UpdateIsNonInteractable(DeltaTime);

// 		if (!CodyHasReleasedTriggerSinceInteracting)
// 		{
// 			if (!MagnetComponent.IsInfluencedBy(Game::GetCody()))
// 			{
// 				CodyHasReleasedTriggerSinceInteracting = true;
// 			}
// 		}

// 		if (!MayHasReleasedTriggerSinceInteracting)
// 		{
// 			if (!MagnetComponent.IsInfluencedBy(Game::GetMay()))
// 			{
// 				MayHasReleasedTriggerSinceInteracting = true;
// 			}
// 		}
// 		MeshComponent.SetPhysicsAngularVelocityInDegrees(FVector::ZeroVector);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if(GetOnlyIsAttracting())
// 		{
// 			MeshComponent.SetPhysicsLinearVelocity(FVector::ZeroVector);
// 		}
		
// 		ClampMaxSpeed();

// 		if (MagnetComponent.ResultingForce < 0)
// 		{
// 			MeshComponent.AddImpulse(RepulsionVector, FName(""), true);
// 		}

// 		else
// 		{
// 			MeshComponent.AddForce(GetAttractionDesiredDirection() * AttractionVelocity, FName("") ,  true);
// 		}

// 		TrackAndSetRotation(DeltaTime);

// 		if (ShouldForceReleasePlayer(DeltaTime))
// 		{
// 			ReleaseAttractedObject();
// 		}
// 	}

// 	void UpdateVibrations(float DeltaTime)
// 	{

// 		FRotator Rotator;
// 		Rotator = FVector::RightVector.Rotation();
// 		Rotator += FVector::ForwardVector.Rotation();

// 		if(FMath::RandBool())
// 		{
// 			Rotator *= 1;
// 		}

// 		else
// 		{
// 			Rotator *= -1;
// 		}
		
// 		MeshComponent.AddLocalRotation(Rotator * DeltaTime);
// 		FVector Upforce = FVector::UpVector;

// 		Upforce *= MeshComponent.WorldLocation.Z - GetControllingPlayer().GetActorLocation().Z;
// 		MeshComponent.AddForce(Upforce);
// 	}

// 	AHazePlayerCharacter GetControllingPlayer()
// 	{
// 		if (MagnetComponent.IsInfluencedBy(Game::GetMay()))
// 		{
// 			return Game::GetMay();
// 		}

// 		else if (MagnetComponent.IsInfluencedBy(Game::GetCody()))
// 		{
// 			return Game::GetCody();
// 		}

// 		else
// 		{
// 			return nullptr;
// 		}
// 	}

// 	void ClampMaxSpeed()
// 	{
// 		FVector Velocity = MeshComponent.GetPhysicsLinearVelocity();
// 		Velocity.GetClampedToSize(0 ,MaxVelocity);
// 		MeshComponent.SetPhysicsLinearVelocity(Velocity);
// 	}

// 	bool GetOnlyIsAttracting()
// 	{
// 		return (MagnetComponent.ResultingForce > 0);
// 	}

// 	FVector GetRepulsionVector()
// 	{
// 		FVector RepulsionVector;
// 		TArray<FMagnetInfluencer> Influencers;
// 		MagnetComponent.GetInfluencers(Influencers);
// 		for(const FMagnetInfluencer& Value : Influencers)
// 		{
// 			RepulsionVector += Owner.GetActorLocation() - Value.Instigator.ActorLocation;
// 		}
// 		RepulsionVector.Z = 1;
// 		RepulsionVector.Normalize();

// 		RepulsionVector *= 10;
// 		return RepulsionVector;
// 	}

// 	float GetDistanceToControllingPlayer()
// 	{
// 		float Distance = 0;
// 		int Iterations = 0;

// 		TArray<FMagnetInfluencer> Influencers;
// 		MagnetComponent.GetInfluencers(Influencers);
// 		for(const FMagnetInfluencer& Value : Influencers)
// 		{
// 			Distance += Value.Instigator.ActorLocation.Distance(Owner.ActorLocation);
// 			Iterations++;
// 		}

// 		if (Influencers.Num() > 0)
// 		{
// 			Distance / Influencers.Num();
// 			return Distance;
// 		}

// 		else 
// 		{
// 			return 0;
// 		}
// 	}

// 	FVector GetExtents()
// 	{
// 		FVector ObjOrigin;
// 		FVector ObjExtents;
// 		Owner.GetActorBounds(false, ObjOrigin, ObjExtents);
// 		return ObjExtents;
// 	}

// 	float GetAttractionVelocity()
// 	{
// 		if (GetDistanceToControllingPlayer() < GetExtents().Size() * 2)
// 		{
// 			return 0;
// 		}

// 		if (GetAttractionDesiredDirection().Distance(Owner.ActorLocation) < 30)
// 		{
// 			return 250;
// 		}

// 		else
// 		{
// 			return 350;
// 		}
// 	}
// }