import Vino.Pickups.PickupActor;
import Vino.Pickups.PickupTags;

class UPickupFloorAttacherCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::PickupSystem);
	default CapabilityTags.Add(PickupTags::PickupFloorAttacherCapability);

	default CapabilityDebugCategory = PickupTags::PickupSystem;

	APickupActor PickupOwner;

	bool bShouldActivate;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PickupOwner = Cast<APickupActor>(Owner);

		UpdateCurrentFloor();

		// Bind delegates
		PickupOwner.OnStoppedMovingAfterThrowEvent.AddUFunction(this, n"OnStoppedMovingAfterThrow");
		PickupOwner.OnPlacedOnFloorEvent.AddUFunction(this, n"OnPlacedOnFloor");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!bShouldActivate)
			return EHazeNetworkActivation::DontActivate;
		
		if(PickupOwner.IsPickedUp())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	// Formerly 'updateCurrentFloor() in PickupableComponent'
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UpdateCurrentFloor();
		bShouldActivate = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	void UpdateCurrentFloor()
	{
		// No floor if it's being carried
		if(PickupOwner.IsPickedUp())
			return;

		// Shoot ray downwards
		TArray<FHitResult> HitResults;
		Trace::SweepComponentForHits(PickupOwner.Mesh, FVector(0.f, 0.f, -20.f), HitResults);

		// No floor in reach
		if(HitResults.Num() == 0)
			return;

		// Find valid floor actor
		for(auto HitResult : HitResults)
		{
			if(HitResult.Actor == nullptr)
				continue;

			// We don't another pickupable as floor!
			if(HitResult.Actor.IsA(APickupActor::StaticClass()))
				continue;

			// Floor is still the same
			// if(CurrentFloor != nullptr && HitResult.Actor == CurrentFloor.Owner)
			// 	break;

			// Players can't be floor, you silly goose you
			if(HitResult.Actor.IsA(AHazePlayerCharacter::StaticClass()))
				continue;

			// Don't attach if this wasn't a blocking hit
			if(!HitResult.bBlockingHit)
				continue;

			// Only attach if the component is movable
			if (HitResult.Component.GetMobility() != EComponentMobility::Static)
			{
				AttachToFloor(HitResult.Component);
				break;
			}
		}

		///////////////////////////////////////
		// Use MovementComponent instead once putdown uses it 
		// No floor if it's being carried
		// if(PickupOwner.IsPickedUp())
		// 	return;

		// const FHitResult& DownHit = PickupOwner.MovementComponent.DownHit;
		// if(!DownHit.bBlockingHit)
		// 	return;

		// if(DownHit.Actor == nullptr)
		// 	return;

		// // We don't want another pickupable as floor!
		// if(DownHit.Actor.IsA(APickupActor::StaticClass()))
		// 	return;

		// // Players can't be a floor, you silly goose you
		// if(DownHit.Actor.IsA(AHazePlayerCharacter::StaticClass()))
		// 	return;

		// // Only attach if the component is movable
		// if(DownHit.Component.GetMobility() == EComponentMobility::Static)
		// 	return;

		// AttachToFloor(DownHit.Component);
	}

	void AttachToFloor(USceneComponent FloorSceneComponent)
	{
		Owner.AttachToComponent(FloorSceneComponent, AttachmentRule = EAttachmentRule::KeepWorld);
		Owner.SetActorRotation( FRotator(0, Owner.GetActorRotation().Yaw, 0) );
	}

	UFUNCTION(NotBlueprintCallable)
	void OnStoppedMovingAfterThrow()
	{
		bShouldActivate = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlacedOnFloor(AHazePlayerCharacter PlayerCharacter, APickupActor PickupActor)
	{
		bShouldActivate = true;
	}
}