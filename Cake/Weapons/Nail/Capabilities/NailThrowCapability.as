
import Vino.Pierceables.PiercingComponent;
import Vino.Pierceables.PierceableComponent;
import Vino.Pierceables.PierceStatics;

import Cake.Weapons.Nail.NailWeaponActor;
import Cake.Weapons.Nail.NailWielderComponent;
import Cake.Weapons.Nail.NailWeaponStatics;

import Vino.Movement.Components.MovementComponent;

import Peanuts.Aiming.AutoAimStatics;
import Cake.Weapons.Nail.NailWeaponMovementComponent;

/**
 * Will throw the most recent nail that the wielder equipped.  
 */

UCLASS(abstract)
class UNailThrowCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Weapon");
	default CapabilityTags.Add(n"NailThrow");
	default CapabilityTags.Add(n"NailWeapon");
	default CapabilityTags.Add(ActionNames::WeaponFire);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	default TickGroupOrder = 140;

	///////////////////////////////////////////////////////////

	// TEMP during rewrite
	UPROPERTY(Category = "Throw")
	// float TimeBetweenThrows = 1.0f;
	float TimeBetweenThrows = 0.7f;
	float TimeStampThrow = -TimeBetweenThrows;

	UPROPERTY(Category = "Throw")
	float ThrowStrength = 20000.f;

	UPROPERTY(Category = "Throw")
	float ThrowTraceLength = 10000.f;

	UPROPERTY(Category = "Throw")
	float AutoAimMinDistance = 100.f;

	/** We need other collision channels to block this weapon channel. */
	UPROPERTY(Category = "Throw")
	ETraceTypeQuery ThrowTraceChannel;

	// Settings
	//////////////////////////////////////////////////////////////////////////
	// Transients 

	FVector NailThrowLocation;			// (Only relevant for replica)
	FRotator NailThrowRotation;			// (Only relevant for replica)
	FRotator NailThrowWorldAimRotation;	// (Only relevant for replica)
	ANailWeaponActor NailToBeThrown;	
	FTimerHandle TimerNailThrow;		

	UHazeActiveCameraUserComponent CameraUser = nullptr;
	UNailWielderComponent WielderComp = nullptr;
	AHazePlayerCharacter Player = nullptr;
	UHazeMovementComponent MoveComp = nullptr;
	UHazeCrumbComponent CrumbComp = nullptr;

	TArray<FNailTargetData> QueuedTargetData;
	TArray<ANailWeaponActor> NailsWaitingForTargetData;

	// Transient 
	//////////////////////////////////////////////////////////////////////////
	// Capability Functions

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WielderComp = UNailWielderComponent::GetOrCreate(Owner);
		CameraUser = UHazeActiveCameraUserComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!WasActionStarted(ActionNames::WeaponFire))
			return EHazeNetworkActivation::DontActivate;

		if(!WielderComp.HasNailEquippedToHand())
			return EHazeNetworkActivation::DontActivate;

 		if(!WielderComp.bAiming)
			return EHazeNetworkActivation::DontActivate;

		if(Time::GetGameTimeSince(TimeStampThrow) < TimeBetweenThrows)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(WielderComp.NailEquippedToHand == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!System::IsTimerActiveHandle(TimerNailThrow))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		// (network ensure) This shouldn't trigger on only 1 side!
		ensure(!IsBlocked());

		// OutParams.EnableTransformSynchronizationWithTime();

		OutParams.AddObject(n"NailEquippedToHand", WielderComp.NailEquippedToHand);
		OutParams.AddVector(n"PlayerLoc", Player.GetActorLocation());
		OutParams.AddVector(n"PlayerRot", Player.GetActorRotation().Euler());
		OutParams.AddVector(n"PlayerViewRot", Player.GetPlayerViewRotation().Euler());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams) 
	{
		NailThrowLocation = ActivationParams.GetVector(n"PlayerLoc");
		NailThrowRotation = FRotator::MakeFromEuler(ActivationParams.GetVector(n"PlayerRot"));
		NailThrowWorldAimRotation = FRotator::MakeFromEuler(ActivationParams.GetVector(n"PlayerViewRot"));
		NailToBeThrown = Cast<ANailWeaponActor>(ActivationParams.GetObject(n"NailEquippedToHand"));

		Owner.BlockCapabilities(n"NailUnequip", this);
		Owner.BlockCapabilities(n"NailEquip", this);

		ensure(NailToBeThrown != nullptr);

		TimeStampThrow = Time::GetGameTimeSeconds();

		// Move replica to the correct position
		if (!HasControl()) 
 			CameraUser.SnapCamera(NailThrowWorldAimRotation.Vector());

		ExecuteThrow();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams) 
	{
		Owner.UnblockCapabilities(n"NailUnequip", this);
		Owner.UnblockCapabilities(n"NailEquip", this);

		if (System::IsTimerActiveHandle(TimerNailThrow))
		{
  			System::ClearAndInvalidateTimerHandle(TimerNailThrow);
			ExecuteThrow();
		}
	}

	// Capability Functions
	//////////////////////////////////////////////////////////////////////////
	// Gameplay functions 

 	void ExecuteThrow()
	{
		if (HasControl())
		{
			ensure(WielderComp.NailEquippedToHand == NailToBeThrown);
			FNailTargetData TargetData;
			GatherTargetData(TargetData);

			NetSendTargetData(TargetData);
			FHazeDelegateCrumbParams CrumbParams;
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbThrowNail"), CrumbParams);
		}
		else
		{
			if (QueuedTargetData.Num() != 0)
			{
				ensure(QueuedTargetData.Num() == 1);
				ThrowNail(NailToBeThrown, QueuedTargetData[0]);
				QueuedTargetData.RemoveAt(0);
			}
			else
			{
				NailsWaitingForTargetData.Add(NailToBeThrown);
				NailToBeThrown = nullptr;
			}
		}
	}
	UFUNCTION(NetFunction)
	void NetSendTargetData(FNailTargetData InTargetData)
	{
		QueuedTargetData.Add(InTargetData);
	}

	UFUNCTION()
	void CrumbThrowNail(const FHazeDelegateCrumbData& CrumbData)
	{
		if (HasControl())
		{
			ensure(QueuedTargetData.Num() == 1);
			ThrowNail(NailToBeThrown, QueuedTargetData[0]);
			QueuedTargetData.RemoveAt(0);
		}
		else if (NailsWaitingForTargetData.Num() != 0)
		{
			ensure(QueuedTargetData.Num() != 0);
			ensure(QueuedTargetData.Num() == 1);
			ensure(NailsWaitingForTargetData.Num() == 1);
			ThrowNail(NailsWaitingForTargetData[0], QueuedTargetData[0]);
			NailsWaitingForTargetData.RemoveAt(0);
			QueuedTargetData.RemoveAt(0);
		}

	}

	void ThrowNail(ANailWeaponActor InNail, FNailTargetData InTargetData)
	{
		RemoveNailWeaponFromWielder(InNail);
		WielderComp.ThrowNail(InNail, InTargetData, ThrowStrength);
		ensure(!WielderComp.NailsThrown.Contains(WielderComp.NailEquippedToHand));
	}

	bool GatherTargetData(FNailTargetData& InOutTargetData)
	{

		/*
			1. auto aim trace when possible. Otherwise:
			2. Trace from camera to get impact point
			3. trace from weapon towards the impact point retrieved from the camera trace.
		*/
		
 		const FVector PlayerViewDirection = Player.GetViewRotation().Vector();
 		const FVector PlayerViewLocation = Player.GetViewLocation();
		
		FAutoAimLine Aim = GetAutoAimForTargetLine(
			Player,
			PlayerViewLocation,
			PlayerViewDirection,
			AutoAimMinDistance,
			ThrowTraceLength,
			bCheckVisibility = true 
		);

		if (!Aim.AimLineDirection.IsNormalized())
			Aim.AimLineDirection.Normalize();

		const FVector CameraTraceEnd = Aim.AimLineStart + (Aim.AimLineDirection * ThrowTraceLength);

		// Handle valid AutoAim
		if(Aim.bWasAimChanged && Aim.AutoAimedAtComponent != nullptr)
		{
			InOutTargetData.bHoming = true;
			InOutTargetData.bWasHoming = true;

			InOutTargetData.SetTargetLocation(
				Aim.AutoAimedAtComponent.GetWorldLocation(),
				FVector::ZeroVector,
				Aim.AutoAimedAtComponent,
				NAME_None
			);

			InOutTargetData.TraceEnd = CameraTraceEnd;
			InOutTargetData.Direction = Aim.AimLineDirection;

			return true; // !!!
		}

		// change camera trace start location depending on if the nail is in front or behind the nail.
		const ANailWeaponActor WeaponToTraceFrom = WielderComp.NailEquippedToHand;
		const FVector NailPos = WeaponToTraceFrom.GetActorLocation(); 
		const FVector CameraTraceStart = FMath::ClosestPointOnLine(Aim.AimLineStart, CameraTraceEnd, NailPos);

		FHitResult CamTraceData;
		bool bHit = RayTrace(CameraTraceStart, CameraTraceEnd, CamTraceData);

		// change weapon trace start location depending on if the camera is in front or behind the nail.
		const FVector WeaponTraceStart = FMath::ClosestPointOnLine(
			NailPos,
			CamTraceData.bBlockingHit ? CamTraceData.ImpactPoint : CamTraceData.TraceEnd,
			Aim.AimLineStart
		);

		// calculate WeaponTraceEnd based on direction. Important that we don't use the impact point 
		// from the camera trace because those traces will fail from certain angle due to the traceEnd
		// being exactly on the surface of the component we want to hit. 
		FVector WeaponTraceDirection = CamTraceData.bBlockingHit ? CamTraceData.ImpactPoint : CamTraceData.TraceEnd;
		WeaponTraceDirection -= WeaponTraceStart;
		WeaponTraceDirection.Normalize();
		const FVector WeaponTraceEnd = WeaponTraceStart + (WeaponTraceDirection * ThrowTraceLength);

		// free throw in case trace fails
		InOutTargetData.bHoming = false;
		InOutTargetData.TraceEnd = WeaponTraceEnd;
		InOutTargetData.Direction = WeaponTraceDirection;

		// homing trace
		FHitResult WeaponTraceData;
		bHit = RayTrace(WeaponTraceStart, WeaponTraceEnd, WeaponTraceData);

		// if (WeaponTraceData.GetComponent() != nullptr && WeaponTraceData.Component.GetMobility() == EComponentMobility::Movable)
		if (WeaponTraceData.GetComponent() != nullptr)
		{
			InOutTargetData.bHoming = true;
			InOutTargetData.bWasHoming = true;

			InOutTargetData.SetTargetLocation(
				WeaponTraceData.ImpactPoint - WeaponTraceData.ImpactNormal,
				WeaponTraceData.ImpactNormal,
				WeaponTraceData.Component,
				WeaponTraceData.BoneName
			);
		}

		return bHit;
	}

	bool RayTrace(FVector Start, FVector End, FHitResult& OutTraceData)
	{
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(Player);
		ActorsToIgnore.Add(WielderComp.NailEquippedToHand);
		for (auto Nail : WielderComp.NailsEquippedToBack)
			ActorsToIgnore.Add(Nail);

		/* Will only return first blocking hit. No overlaps. */
		const bool bHit = System::LineTraceSingle
		(
			Start,
			End,
			ThrowTraceChannel,
			false,
			ActorsToIgnore,
			EDrawDebugTrace::None,
			OutTraceData,
			true
		);

		return bHit;
	}

}


