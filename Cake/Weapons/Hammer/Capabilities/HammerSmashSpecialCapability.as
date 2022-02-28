
import Cake.Weapons.Hammer.HammerWeaponStatics;
import Cake.Weapons.Hammer.HammerWeaponActor;
import Cake.Weapons.Hammer.HammerableComponent;
import Cake.Weapons.Hammer.HammerWielderComponent;
import Cake.Weapons.Hammer.HammerSocketDefinition;
import Cake.Weapons.Hammer.HammerableStatics;
import Cake.Weapons.Hammer.AnimNotify_HammerSmash;

UCLASS()
class UHammerSmashSpecialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Weapon");
	default CapabilityTags.Add(n"HammerWeapon");
	default CapabilityTags.Add(n"HammerSmash");
	default CapabilityTags.Add(n"BlockWhileLedgeGrabbing");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 1;		// Should be before default.

	// Will be the next attack.
	FHazePlaySlotAnimationParams NextAnimToPlay;

	UHammerWielderComponent	WielderComp = nullptr;
	FHazeAnimNotifyDelegate OnHammerSmashExecuted;
	UHammerWeaponSettings Settings = nullptr;
	AHazePlayerCharacter Player = nullptr;
	AHammerWeaponActor Hammer = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		WielderComp = UHammerWielderComponent::GetOrCreate(Owner);
		Hammer = WielderComp.GetHammer();
		Player = Cast<AHazePlayerCharacter>(Owner);
		Settings = UHammerWeaponSettings::GetSettings(Hammer);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::WeaponFire))
			return EHazeNetworkActivation::DontActivate;

		if(Settings.Special.AnimData.Sequences.Num() <= 0)
			return EHazeNetworkActivation::DontActivate;

		// if (!ShouldTriggerSpecialAttack())
		// 	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(ActionNames::WeaponFire))
			return EHazeNetworkDeactivation::DontDeactivate;

		if (WielderComp.IsDoingHammeringAnimation())
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(n"HammerSmash", true);

		if (NextAnimToPlay.Animation == nullptr)
			PickNextAnimationToPlay();

		PlaySmashAnimation();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams) 
	{
		SetMutuallyExclusive(n"HammerSmash", false);
		NextAnimToPlay.Animation = nullptr;
	}

	// Will do special attack if at least we have x amount of hammerables around us.
	bool ShouldTriggerSpecialAttack() const
	{ 
		TArray<AActor> HitActors;
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.AddUnique(Player);
		ActorsToIgnore.AddUnique(Hammer);

		GetHammerableActorsFromSphereTrace(
			HitActors,
			ActorsToIgnore,
			Hammer.GetActorLocation(),
			Settings.Special.SphereTraceRadius,
			ETraceTypeQuery::WeaponTrace
		);

		// Only trigger for certain classes, if specified.  
		if (Settings.Special.TriggerOnHammerableActorClasses.Num() > 0)
		{
			for (int i = HitActors.Num() - 1; i >= 0; i--)
			{
				if (ShouldTriggerForActor(HitActors[i]) == false)
				{
					HitActors.RemoveAt(i);
				}
			}
		}

		if(Settings.bDrawDebug)
			System::DrawDebugSphere(Hammer.GetActorLocation(), Settings.Special.SphereTraceRadius, Duration = 5.f);

		if (HitActors.Num() >= Settings.Special.NumHammerablesThatTriggerSpecial)
			return true;

		return false;
	}

	bool ShouldTriggerForActor(AActor Actor) const
	{
		// Trigger for all actors if no specification has been made.
		if (Settings.Special.TriggerOnHammerableActorClasses.Num() <= 0)
			return true;

		for (auto SubClass : Settings.Special.TriggerOnHammerableActorClasses)
		{
            if (!SubClass.IsValid())
                continue;
            if (Actor.IsA(SubClass))
                return true;
		}

		return false;
	}

	UFUNCTION()
	void PlaySmashAnimation()
	{
		if (HasControl())
			NetStartHammering(NextAnimToPlay.Animation);

		OnHammerSmashExecuted.BindUFunction(this, n"HandleNotify_DoHammerSmash");
		Player.BindOrExecuteOneShotAnimNotifyDelegate(
			NextAnimToPlay.Animation,
			UAnimNotify_HammerSmash::StaticClass(),
			OnHammerSmashExecuted
		);

		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		Player.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, NextAnimToPlay);
//		Player.PlayEventAnimation(OnBlendingIn, OnBlendingOut, NextAnimToPlay.Animation);
		// Player.PlayEventAnimation(OnBlendingIn, OnBlendingOut, NextAnimToPlay);
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

		FVector SmashDirection = Player.GetActorForwardVector();
		SmashDirection = SmashDirection.VectorPlaneProject(FVector::UpVector);
		SmashDirection.Normalize();

		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.AddUnique(Player);
		ActorsToIgnore.AddUnique(Hammer);

		TArray<UPrimitiveComponent> HammerablePrimitivesHit;
		// const bool bHitAnything = GetHammerablePrimitivesFromSphereTrace(
		// 	HammerablePrimitivesHit,
		// 	ActorsToIgnore,
		// 	TraceStartLocation,
		// 	Settings.Special.SphereTraceRadius,
		// 	ETraceTypeQuery::WeaponTrace
		// );
		const bool bHitAnything = GetHammerablePrimitivesFromConeTrace( 
			HammerablePrimitivesHit,
			ActorsToIgnore,
			TraceStartLocation,
			SmashDirection,
			Settings.Default.ConeTraceAngle,
			Settings.Default.ConeTraceLength,
			ETraceTypeQuery::WeaponTrace,
			Settings.bDrawDebug
		);

		// if(Settings.bDrawDebug)
		// {
		// 	FLinearColor DebugColor = HammerablePrimitivesHit.Num() > 0 ? FLinearColor::Yellow : FLinearColor::White;
		// 	System::DrawDebugSphere(TraceStartLocation, Settings.Special.SphereTraceRadius, LineColor = DebugColor);
		// }

		NetEndHammering(HammerablePrimitivesHit);
	}

	UFUNCTION(NetFunction)
	void NetEndHammering(TArray<UPrimitiveComponent> HammerablePrimitives)
	{
		NotifyHammerableComponentsOfHit(Owner, HammerablePrimitives);

		// For Audio (we need to know if we hit anything solid at all)
		FHitResult NoseHitData;
		Hammer.SphereTraceHammerNoseForHit(NoseHitData);
		WielderComp.OnHammerHit.Broadcast(NoseHitData);

		WielderComp.SetDoingHammeringAnimation(false);
	}

	UFUNCTION(NetFunction)
	void NetStartHammering(UAnimSequence AnimBeingPlayed)
	{
		WielderComp.SetDoingHammeringAnimation(true);
	}

	void PickNextAnimationToPlay() 
	{
		NextAnimToPlay.Animation = Settings.Special.AnimData.GetRandomAnimationWithException(NextAnimToPlay.Animation);
		NextAnimToPlay.bLoop = Settings.Special.AnimData.bLoop;
		NextAnimToPlay.PlayRate = Settings.Special.AnimData.PlayRate;
		NextAnimToPlay.BlendType = EHazeBlendType::BlendType_Inertialization;
		NextAnimToPlay.BlendTime = Settings.Special.BlendTime;
	}

}
















