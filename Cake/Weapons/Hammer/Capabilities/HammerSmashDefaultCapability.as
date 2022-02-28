
import Cake.Weapons.Hammer.HammerWeaponStatics;
import Cake.Weapons.Hammer.HammerWeaponActor;
import Cake.Weapons.Hammer.HammerableComponent;
import Cake.Weapons.Hammer.HammerWielderComponent;
import Cake.Weapons.Hammer.HammerSocketDefinition;
import Cake.Weapons.Hammer.HammerableStatics;
import Cake.Weapons.Hammer.AnimNotify_HammerSmash;

import Cake.Weapons.Hammer.HammerWeaponSettings;
import Vino.Characters.PlayerCharacter;

struct FNetHammerablePrimitives
{
	TArray<UPrimitiveComponent> HammerablePrimitives;

	FNetHammerablePrimitives(TArray<UPrimitiveComponent> InPrims)
	{
		HammerablePrimitives = InPrims;
	}
};

UCLASS()
class UHammerSmashDefaultCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Weapon");
	default CapabilityTags.Add(n"HammerWeapon");
	default CapabilityTags.Add(n"HammerSmash");
	default CapabilityTags.Add(n"BlockWhileLedgeGrabbing");
	default CapabilityTags.Add(n"BlockWhileSliding");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 2; // should be after special

	UHammerWielderComponent	WielderComp = nullptr;
	FHazeAnimNotifyDelegate OnHammerSmashExecuted;
	UHammerWeaponSettings Settings = nullptr;
	APlayerCharacter Player = nullptr;
	AHammerWeaponActor Hammer = nullptr;
	UHazeMovementComponent MoveComp = nullptr;
	UHazeCrumbComponent CrumbComp = nullptr;

	float TimeStampHammerSmash= 0.f;
	int NumConsecutiveHammerSmashes = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<APlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Player);
		WielderComp = UHammerWielderComponent::GetOrCreate(Owner);
		Hammer = WielderComp.GetHammer();
		Settings = UHammerWeaponSettings::GetSettings(Hammer);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (MoveComp.IsGrounded() && WasActionStarted(ActionNames::WeaponFire))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		// Smashes done while in air, within the time-frame since we landed, are flagged as valid
		if(MoveComp.BecameGrounded() && WasActionStartedDuringTime(ActionNames::WeaponFire, 0.1f))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WielderComp.IsDoingHammeringAnimation())
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(n"HammerSmash", true);
		PlaySmashAnimation();
		Owner.BlockCapabilities(MovementSystemTags::Jump, this);

		HandleConsecutiveSmashing();
	}

	void HandleConsecutiveSmashing()
	{
		const float TimeSinceLastSmash = Time::GetGameTimeSince(TimeStampHammerSmash);

		if(TimeSinceLastSmash <= 2.0f)
		{
			if(NumConsecutiveHammerSmashes >= 6)
			{
//				Print("Aw my head!");
				Player.SetCapabilityActionState(n"FoghornSBHammerSwingHammerhead", EHazeActionState::ActiveForOneFrame);
				NumConsecutiveHammerSmashes = 0;
			}
		}
		else
		{
			NumConsecutiveHammerSmashes = 0;
		}

//		Print("NumConsecutiveHammerSmashes: " + NumConsecutiveHammerSmashes, 4.f, FLinearColor::Yellow);
//		Print("TimeSinceSmash: " + TimeSinceLastSmash, 4.f, FLinearColor::Yellow);

		++NumConsecutiveHammerSmashes;
		TimeStampHammerSmash = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams) 
	{
		SetMutuallyExclusive(n"HammerSmash", false);
		Owner.UnblockCapabilities(MovementSystemTags::Jump, this);
	}	

	UFUNCTION()
	void PlaySmashAnimation()
	{
		if (HasControl())
		{
			FHazeDelegateCrumbParams CrumbParams;
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbStartHammering"), CrumbParams);
		}

		OnHammerSmashExecuted.BindUFunction(this, n"HandleNotify_DoHammerSmash");
		Player.BindOrExecuteOneShotAnimNotifyDelegate(
			Settings.Default.AnimData.Animation,
			UAnimNotify_HammerSmash::StaticClass(),
			OnHammerSmashExecuted
		);

		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		Player.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, Settings.Default.AnimData);
	}

	UFUNCTION()
	void HandleNotify_DoHammerSmash(
		AHazeActor Actor,
		UHazeSkeletalMeshComponentBase SkelMesh,
		UAnimNotify AnimNotify
	)
	{
		if (!HasControl())
			return;

		const FVector HammerPos = Hammer.GetActorLocation();
		const FVector PlayerPos = Player.GetActorLocation();
		const FVector OffsetBetweenPlayerAndHammer = HammerPos - PlayerPos;
		FVector TraceStartLocation = PlayerPos + OffsetBetweenPlayerAndHammer * 0.5f;
		TraceStartLocation.Z = HammerPos.Z;

		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.AddUnique(Player);
		ActorsToIgnore.AddUnique(Hammer);

		FVector SmashDirection = Player.GetActorForwardVector();
		SmashDirection = SmashDirection.VectorPlaneProject(GetGroundNormal());
		SmashDirection.Normalize();

		TArray<UPrimitiveComponent> HammerablePrimitivesWithinCone;
		GetHammerablePrimitivesFromConeTrace( 
			HammerablePrimitivesWithinCone,
			ActorsToIgnore,
			TraceStartLocation,
			SmashDirection,
			Settings.Default.ConeTraceAngle,
			Settings.Default.ConeTraceLength,
			ETraceTypeQuery::WeaponTrace,
			Settings.bDrawDebug
		);

		NetSendHammerablePrimitives(FNetHammerablePrimitives(HammerablePrimitivesWithinCone));
		FHazeDelegateCrumbParams CrumbParams;
		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbEndHammering"), CrumbParams);
	}

	UFUNCTION()
	void CrumbStartHammering(const FHazeDelegateCrumbData& CrumbData)
	{
		WielderComp.TimeStampAnimationStarted = Time::GetGameTimeSeconds();
		WielderComp.SetDoingHammeringAnimation(true);
	}

	UFUNCTION()
	void CrumbEndHammering(const FHazeDelegateCrumbData& CrumbData)
	{
		NotifyHammerableComponentsOfHit(Owner, QueuedHammarablePrimitives[0].HammerablePrimitives);
		QueuedHammarablePrimitives.RemoveAt(0);

		// For Audio (we need to know if we hit anything solid at all)
		FHitResult NoseHitData;
		Hammer.SphereTraceHammerNoseForHit(NoseHitData, GetGroundNormal());
		WielderComp.OnHammerHit.Broadcast(NoseHitData);

		WielderComp.SetDoingHammeringAnimation(false);
	}

	TArray<FNetHammerablePrimitives> QueuedHammarablePrimitives;

	UFUNCTION(NetFunction)
	void NetSendHammerablePrimitives(FNetHammerablePrimitives HammerablePrimitives)
	{
		QueuedHammarablePrimitives.Add(HammerablePrimitives);
	}

	FVector GetGroundNormal() const
	{
		FVector TheNormal = FVector::UpVector;

		auto PlayerMoveComp = UHazeBaseMovementComponent::Get(Owner);
		const FHitResult& HitData = PlayerMoveComp.Impacts.DownImpact;
		if (HitData.bBlockingHit)
			TheNormal = HitData.Normal;

		return TheNormal;
	}

}
















