
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
import Cake.LevelSpecific.Tree.Swarm.Animation.AnimNotifies.AnimNotify_SwarmAttackUltimate;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.SwarmHammerComponent;
import Cake.LevelSpecific.Tree.Swarm.Encounters.Hammer.SwarmHammerManager;
import Cake.LevelSpecific.Tree.Swarm.Animation.AnimNotifies.AnimNotify_SwarmPummel;

class USwarmHammerAttackUltimateCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::AttackUltimate;

	FHazeAnimNotifyDelegate OnNotifyExecuted_AttackUltimate;
	FHazeAnimNotifyDelegate OnNotifyExecuted_Pummel;

	USwarmHammerComponent HammerComp = nullptr;

	FQuat StartQuat = FQuat::Identity;
	ASwarmHammerManager Manager;

	// Ultimate animation states
	float TimestampUltimateStartedPlaying = -1.f;
	bool bPlayedHammerEnter = false;
	bool bUltimatePerformed = false;

	// pummel
	int PummelCounter = 1;
	bool bStartedPummeling = false;
	float TimestampPummelStartedPlaying = -1.f;
	int PummelCounter_TriggerUltimateThreshold = 4;
	int PummelCounter_DeactivateCapability = PummelCounter_TriggerUltimateThreshold + 1;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if (MoveComp.ArenaMiddleActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(bUltimatePerformed)
			return EHazeNetworkActivation::DontActivate;

		// if(PummelCounter >= PummelCounter_DeactivateCapability)
		// 	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (SwarmActor.MovementComp.ArenaMiddleActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		// if(PummelCounter >= PummelCounter_DeactivateCapability)
		if(bUltimatePerformed)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Have the swarm go into a comet shape and be invulnerable to damage
		PlayAnimation_TelegraphingComet();

		BehaviourComp.NotifyStateChanged();

		BindOrExecutePummelNotifyDelegate();

		HammerComp = USwarmHammerComponent::Get(SwarmActor);

		StartQuat = SwarmActor.GetActorQuat();
		Manager = Cast<ASwarmHammerManager>(SwarmActor.MovementComp.ArenaMiddleActor);
		MoveComp.DesiredSwarmActorTransform = SwarmActor.GetActorTransform();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PrioritizeState(ESwarmBehaviourState::Recover);

		SwarmActor.StopSwarmAnimationByInstigator(this);
		UnbindPummelNotifyDelegate();

		BroadcastUltimatePerformed();

		ClearCamera_Pummel(Game::May);
		ClearCamera_Pummel(Game::Cody);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (!bPlayedHammerEnter)
		{
			const float TimeElapsed = BehaviourComp.GetStateDuration();
			if (TimeElapsed > Settings.Hammer.AttackUltimate.TelegraphTime)
			{
				// Switch to the pummel slowly 
				PlayAnimation_TelegraphingHammer();
				Manager.HandleHammerUltimateStarted();
			}
		}
		else if(!bStartedPummeling)
		{
			// SwarmActor.AddActorLocalOffset(FVector::UpVector*700.f);
			const float TimesSinceUltimateStartedPlaying = Time::GetGameTimeSince(TimestampUltimateStartedPlaying);

			// float HammerUltiPlayLength = 6.f;	// default duration, due to procedural anims
			// const USwarmAnimationSettingsDataAsset HammerUltiSettingsAsset = Cast<USwarmAnimationSettingsDataAsset>(Settings.Hammer.AttackUltimate.AnimSettingsDataAsset);
			// if(HammerUltiSettingsAsset.Settings.OptionalSwarmAnimation.Sequence != nullptr)
			// 	HammerUltiPlayLength = HammerUltiSettingsAsset.Settings.OptionalSwarmAnimation.Sequence.GetPlayLength();

			// if(TimesSinceUltimateStartedPlaying > HammerUltiPlayLength)
			if(TimesSinceUltimateStartedPlaying > Settings.Hammer.AttackUltimate.BlendInTime)
			{
				// Start consecutively pummel smashing the ground
				PlayAnimation_PummelSmash();
			}
		}
		else if(!bUltimatePerformed)
		{
			// SwarmActor.AddActorLocalOffset(FVector::UpVector*1500.f);
			// make sure cody and may stay away from the swarm while smashing
			UpdatePlayerKnockback();

			// CountPummelSmashes();

			// crack the ground, by notifying Level BP, once we've smashed enough
			if(PummelCounter == PummelCounter_TriggerUltimateThreshold)
			{
				SwarmActor.PropagateAttackUltimatePerformed();
				ClearCamera_Pummel(Game::May);
				ClearCamera_Pummel(Game::Cody);
			}

			// deactivate once we've done a few extra hits, 
			// as if the cracking was unexpected from the swarms POI
			if(PummelCounter >= PummelCounter_DeactivateCapability)
				bUltimatePerformed = true;
		}

		UpdateMovement(DeltaSeconds);

		BehaviourComp.FinalizeBehaviour();
	}

	void UpdatePlayerKnockback()
	{
		// Game::May.SetCapabilityActionState(n"KnockDown", EHazeActionState::Active);
		// Game::Cody.SetCapabilityActionState(n"KnockDown", EHazeActionState::Active);
	}

	void PlayAnimation_TelegraphingComet()
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.Hammer.AttackUltimate.TelegraphAnim,
			this,
			Settings.Hammer.AttackUltimate.TelegraphTime
		);
	}

	void PlayAnimation_TelegraphingHammer()
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.Hammer.AttackUltimate.AnimSettingsDataAsset,
			this,
			Settings.Hammer.AttackUltimate.BlendInTime	// this is correct
			// 0.2f
		);

		bPlayedHammerEnter = true;
		TimestampUltimateStartedPlaying = Time::GetGameTimeSeconds();
	}

	void PlayAnimation_PummelSmash()
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.Hammer.AttackUltimate.PummelAnim,
			this,
			Settings.Hammer.AttackUltimate.BlendInTimePummel
		);

		bStartedPummeling = true;
		TimestampPummelStartedPlaying = Time::GetGameTimeSeconds();

		// const FVector DasImpulse_May = Game::May.ActorLocation - Owner.GetActorLocation();
		// const FVector DasImpulse_Cody = Game::Cody.ActorLocation - Owner.GetActorLocation();
		// Game::May.SetCapabilityAttributeVector(n"KnockdownDirection", DasImpulse_May);
		// Game::Cody.SetCapabilityAttributeVector(n"KnockdownDirection", DasImpulse_Cody);

		ApplyCamera_Pummel(Game::May);
		ApplyCamera_Pummel(Game::Cody);
	}

	void ApplyCamera_Pummel(AHazePlayerCharacter InPlayer)
	{
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 4.f;
		// InPlayer.ApplyCameraSettings(Manager.CameraSettingsUltimate, Blend, this, EHazeCameraPriority::Script);

		/* 	Lower values == more pitch. High values == less pitch */
		const float GoingUpPOIPitchOffset = 3000.f;

		const FVector AlignBoneWorldLocation = SwarmActor.SkelMeshComp.GetSocketTransform(
			n"Align",
			ERelativeTransformSpace::RTS_World
		).GetLocation();

		// Calculate offset direction; which is orthogonal to the line between the nado and the player
		const FVector NadoToPlayer = (AlignBoneWorldLocation - InPlayer.GetActorLocation());
		FVector Ortho = NadoToPlayer.CrossProduct(FVector::UpVector).GetSafeNormal();
		if(Ortho.DotProduct(InPlayer.GetPlayerViewRotation().Vector()) < 0.f)
			Ortho = -Ortho;

		FHazePointOfInterest POI;
		POI.Blend = Blend;
		POI.FocusTarget.Actor = SwarmActor;
		// POI.FocusTarget.WorldOffset = Ortho * GoingUpPOIPitchOffset;
		POI.FocusTarget.WorldOffset = FVector::UpVector * 0.f;

		// InPlayer.ApplyPointOfInterest(POI, this, EHazeCameraPriority::High);

		Manager.ApplyKeepInView(InPlayer);

		// InPlayer.BlockCapabilities(n"MatchWeaponAim", this);
	}

	void ClearCamera_Pummel(AHazePlayerCharacter InPlayer)
	{
		// InPlayer.UnblockCapabilities(n"MatchWeaponAim", this);

		const float BlendOutTime = 2.f;
		InPlayer.ClearIdealDistanceByInstigator(this, BlendOutTime);
		InPlayer.ClearCameraSettingsByInstigator(this, BlendOutTime);
		InPlayer.ClearPointOfInterestByInstigator(this);
		Manager.ClearKeepInView(InPlayer);
	}

	FVector AdditionalOffset = FVector::ZeroVector;

	float GetCurrentBlendInTime() const
	{
		if (!bPlayedHammerEnter)
		{
			// comet
			return Settings.Hammer.AttackUltimate.TelegraphTime;
		}
		// hammer 
		else if(!bStartedPummeling)
		{
			// pummel mh
			// return Settings.Hammer.AttackUltimate.BlendInTime;
			return KINDA_SMALL_NUMBER;
		}
		else
		{
			// pummel smash
			// return Settings.Hammer.AttackUltimate.BlendInTimePummel;
			return KINDA_SMALL_NUMBER;
		}
	}

	void UpdateMovement(const float DeltaSeconds)
	{

		/* Go to the manger location, represented by the yellow sphere 
		 in waspNest (editor), which is placed in the middle of the 'arena' */
		FVector TargetLocation = Manager.HammerUltimateTargetPoint.GetActorLocation();
		FQuat TargetQuat = Manager.HammerUltimateTargetPoint.GetActorQuat();

		float MovementBlendInTime = GetCurrentBlendInTime();
		AdditionalOffset = FVector(0.f, 0.f, 1108.f);

		// if(false)
		if(!bPlayedHammerEnter)
		{
			const float TimeElapsed = BehaviourComp.GetStateDuration();
			float RootMotionAlpha = TimeElapsed / Settings.Hammer.AttackUltimate.TelegraphTime;
			RootMotionAlpha = FMath::Clamp(RootMotionAlpha, 0.f, 1.f);
			RootMotionAlpha = FMath::Pow(RootMotionAlpha, 3.f);
			const float BaseOffset = FMath::Lerp(-500.f, 1108.f, RootMotionAlpha);
			AdditionalOffset = FVector::UpVector * BaseOffset;

			// System::DrawDebugPoint(TargetLocation, 10.f);
			// PrintToScreenScaled("RootMotionAlpha: " + RootMotionAlpha);

			MovementBlendInTime = 0.1f;
		}

		// if(false)
		if(bPlayedHammerEnter && !bStartedPummeling)
		{
			float TimeSinceHammerEnteredStarted = Time::GetGameTimeSince(TimestampUltimateStartedPlaying);
			TimeSinceHammerEnteredStarted += DeltaSeconds;
			float RootMotionAlpha = TimeSinceHammerEnteredStarted / Settings.Hammer.AttackUltimate.BlendInTime;
			RootMotionAlpha = FMath::Clamp(RootMotionAlpha, 0.f, 1.f);
			RootMotionAlpha = FMath::Pow(RootMotionAlpha, 6.f);
			const float BaseOffset = FMath::Lerp(450.f, 1108.f, RootMotionAlpha);
			// const float BaseOffset = FMath::Lerp(500.f, 1108.f, RootMotionAlpha);
			AdditionalOffset = FVector::UpVector * BaseOffset;

			// System::DrawDebugPoint(TargetLocation, 15.f, FLinearColor::Yellow);
			// PrintToScreenScaled("RootMotionAlpha: " + RootMotionAlpha);

			// for(const FSwarmParticle P : SwarmActor.SkelMeshComp.Particles)
			// {
			// 	const int Index = P.Id;
			// 	FName BoneName = SwarmActor.SkelMeshComp.GetParticleBoneName(Index);
			// 	FTransform BoneTM = SwarmActor.SkelMeshComp.GetSocketTransform(BoneName, ERelativeTransformSpace::RTS_World);
			// 	System::DrawDebugPoint(BoneTM.GetLocation(), 10.f);
			// 	System::DrawDebugPoint(P.TargetTransform.GetLocation(), 10.f);
			// 	// System::DrawDebugPoint(P.CurrentTransform.GetLocation(), 30.f);
			// }

			// MovementBlendInTime = 0.1f;
		}

		// Align according to align bone offset when blending to pummel hammer animation
		// because the hammer is supposed to start off at a distance from the ground
		// if(false)
		// if(bPlayedHammerEnter)
		// {
		// 	const FTransform AlignBoneWorldTransform = SwarmActor.SkelMeshComp.GetSocketTransform(
		// 		n"Align",
		// 		ERelativeTransformSpace::RTS_World
		// 	);
		// 	///////////////////////////
		// 	///////////////////////////
		// 	// START DEBUG
		// 	const FVector TraceStart = TargetLocation;
		// 	const FVector TraceEnd = TargetLocation - (FVector::UpVector * 10000.f);
		// 	TArray<AActor>IgnoreActors;
		// 	IgnoreActors.Add(SwarmActor);
		// 	FHitResult OutHit;
		// 	bool bHit = System::LineTraceSingle(
		// 		TraceStart,
		// 		TraceEnd,
		// 		ETraceTypeQuery::WeaponTrace,
		// 		true, // TraceComplex
		// 		IgnoreActors,
		// 		EDrawDebugTrace::None,
		// 		OutHit,
		// 		false
		// 	);
		// 	if(OutHit.Actor == nullptr)
		// 		return;
		// 	const float ZError = (AlignBoneWorldTransform.GetLocation() - OutHit.Location).Z;
		// 	PrintToScreenScaled("Z error: " + ZError, 0.f, FLinearColor::Yellow, 2.f);
		// 	PrintToScreenScaled("What is dis: " + OutHit.Actor.GetName(), 0.f, FLinearColor::Yellow, 2.f);
		// 	PrintToScreenScaled("What is dis bone: " + OutHit.BoneName, 0.f, FLinearColor::Yellow, 2.f);
		// 	// END DEBUG
		// 	///////////////////////////
		// 	///////////////////////////
		// }

		TargetLocation += AdditionalOffset;

		// PrintToScreen("AdditionalOffset: " + AdditionalOffset);
		// const FVector TranslationError = MoveComp.DesiredSwarmActorTransform.Location - TargetLocation;
		// PrintToScreen("TranslationError: " + TranslationError);

		MoveComp.SpringToTargetWithTime(
			TargetLocation,
			MovementBlendInTime,
			DeltaSeconds
		);

		MoveComp.InterpolateToRotationOverTime(
			StartQuat,
			TargetQuat,
			BehaviourComp.GetStateDuration(),
			MovementBlendInTime
		);

	}

	void CountPummelSmashes()
	{
		const float TimesSincePummelStartedPlaying = Time::GetGameTimeSince(TimestampPummelStartedPlaying);
		const USwarmAnimationSettingsDataAsset HammerUltiSettingsAsset = Cast<USwarmAnimationSettingsDataAsset>(Settings.Hammer.AttackUltimate.PummelAnim);
		float PummelPlayLength = HammerUltiSettingsAsset.Settings.OptionalSwarmAnimation.Sequence.GetPlayLength();
		// PummelPlayLength *= 1.25f; // due to 0.8 speed scale
		float CurrentPummelTimeThreshold = PummelPlayLength;

		if (TimesSincePummelStartedPlaying > CurrentPummelTimeThreshold)
		{
			PummelCounter++;
		}
	}

	UFUNCTION()
	void HandleNotify_Pummel(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify AnimNotify)
	{
		// PrintToScreen("Pummel", Duration = 6.f);
		PummelCounter++;
		// PrintToScreen(Owner.GetName() + " | Pummel count! " + PummelCounter, Duration = 3.f);

		const float DesiredImpulseMag = 4000.f;

		const FVector AlignBoneWorldLocation = SwarmActor.SkelMeshComp.GetSocketTransform(
			n"Align",
			ERelativeTransformSpace::RTS_World
		).GetLocation();

		// System::DrawDebugSphere(AlignBoneWorldLocation, 100.f, Duration = 3.f);

		FVector DasImpulse_May = Game::May.ActorLocation - Owner.GetActorLocation();
		const float Dist_May = DasImpulse_May.Size();
		DasImpulse_May.Normalize();
		const float ImpulseMag_May = FMath::Max(0.f, DesiredImpulseMag - Dist_May);
		// PrintToScreen("Impulsemag MAy: " + ImpulseMag_May, 4.f, FLinearColor::Yellow);
		DasImpulse_May *= ImpulseMag_May;

		FVector DasImpulse_Cody = Game::Cody.ActorLocation - Owner.GetActorLocation();
		const float Dist_Cody = DasImpulse_Cody.Size();
		DasImpulse_Cody.Normalize();
		const float ImpulseMag_Cody = FMath::Max(0.f, DesiredImpulseMag - Dist_Cody);
		// PrintToScreen("Impulsemag Cody: " + ImpulseMag_Cody, 4.f, FLinearColor::Yellow);
		DasImpulse_Cody *= ImpulseMag_Cody;

		DasImpulse_May = FVector::ZeroVector;
		DasImpulse_Cody = FVector::ZeroVector;

		// Game::May.SetCapabilityAttributeVector(n"KnockdownDirection", DasImpulse_May);
		// Game::Cody.SetCapabilityAttributeVector(n"KnockdownDirection", DasImpulse_Cody);
		// Game::May.SetCapabilityActionState(n"KnockDown", EHazeActionState::Active);
		// Game::Cody.SetCapabilityActionState(n"KnockDown", EHazeActionState::Active);

//		FVector TargetLocation = Manager.HammerUltimateTargetPoint.GetActorLocation();
//		const FVector TraceStart = TargetLocation;
//		const FVector TraceEnd = TargetLocation - (FVector::UpVector * 10000.f);
//		TArray<AActor>IgnoreActors;
//		IgnoreActors.Add(SwarmActor);
//		FHitResult OutHit;
//		bool bHit = System::LineTraceSingle(
//			TraceStart,
//			TraceEnd,
//			// ETraceTypeQuery::WeaponTrace,
//			ETraceTypeQuery::Visibility,
//			true, // TraceComplex
//			IgnoreActors,
//			EDrawDebugTrace::None,
//			OutHit,
//			false
//		);
//		OutHit.Component.AddRadialImpulse(OutHit.ImpactPoint, 700.f, 50000.f, ERadialImpulseFalloff::RIF_Linear, true);

	}

	UFUNCTION()
	void HandleNotify_UltimateAttack(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify AnimNotify)
	{
		if (!HasControl())
			return;

		if (bUltimatePerformed)
			return;

		NetBroadcastUltimatePerformed();
	}

	UFUNCTION(NetFunction)
	void NetBroadcastUltimatePerformed()
	{
		BroadcastUltimatePerformed();
	}

	UFUNCTION(NetFunction)
	void BroadcastUltimatePerformed()
	{
		if (bUltimatePerformed)
			return;

		bUltimatePerformed = true;
		SwarmActor.PropagateAttackUltimatePerformed();
	}

	// Ulti
	void UnbindUltimateNotifyDelegate()
	{
		SwarmActor.UnbindOneShotAnimNotifyDelegate(
			UAnimNotify_SwarmAttackUltimate::StaticClass(),
			OnNotifyExecuted_AttackUltimate
		);
	}

	// Ulti
	void BindOrExecuteUltimateNotifyDelegate()
	{
		OnNotifyExecuted_AttackUltimate.BindUFunction(this, n"HandleNotify_UltimateAttack");
		Owner.BindOrExecuteOneShotAnimNotifyDelegate(
			GetSequenceFromSwarmAnimDataAsset(Settings.Hammer.AttackUltimate.AnimSettingsDataAsset),
			UAnimNotify_SwarmAttackUltimate::StaticClass(),
			OnNotifyExecuted_AttackUltimate
		);
	}

	// Pummel
	void UnbindPummelNotifyDelegate()
	{
		SwarmActor.UnbindAnimNotifyDelegate(
			UAnimNotify_SwarmPummel::StaticClass(),
			OnNotifyExecuted_Pummel
		);
	}

	// Pummel
	void BindOrExecutePummelNotifyDelegate()
	{
		OnNotifyExecuted_Pummel.BindUFunction(this, n"HandleNotify_Pummel");
		Owner.BindAnimNotifyDelegate(
			UAnimNotify_SwarmPummel::StaticClass(),
			OnNotifyExecuted_Pummel
		);
	}

}
