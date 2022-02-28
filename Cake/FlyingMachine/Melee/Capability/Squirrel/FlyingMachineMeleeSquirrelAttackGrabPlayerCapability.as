
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeSquirrelComponent;
import Cake.FlyingMachine.Melee.FlyingMachineMeleeNut;
import Cake.FlyingMachine.Melee.AnimNotify.AnimNotify_MeleeSquirrelShootNut;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightAttack;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightThrown;

class UFlyingMachineMeleeSquirrelAttackGrabPlayerCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(MeleeTags::MeleeSquirrelAi);
	default CapabilityTags.Add(MeleeTags::MeleeAttack);
	default CapabilityTags.Add(MeleeTags::MeleeAttackSpecial);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	default CapabilityDebugCategory = MeleeTags::Melee;

	default TickGroupOrder = 99;

	// InternalParams
	AHazeCharacter Squirrel = nullptr;
	UFlyingMachineMeleeSquirrelComponent SquirrelMeleeComponent;

	FHazeMeleeTarget PlayerTarget;
	bool bHasTarget = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Squirrel = Cast<AHazeCharacter>(Owner);
		SquirrelMeleeComponent = UFlyingMachineMeleeSquirrelComponent::Get(Squirrel);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Store the target
		bHasTarget = MeleeComponent.GetCurrentTarget(PlayerTarget);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

        if(!bHasTarget)
            return EHazeNetworkActivation::DontActivate;

		if(!SquirrelMeleeComponent.HasPendingAttackGrabPlayer())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsStateActive(EHazeMeleeStateType::Attack))
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		// Force the squirrel to face the correct way
		ULocomotionFeaturePlaneFightGrab GrabFeature = Cast<ULocomotionFeaturePlaneFightGrab>(SquirrelMeleeComponent.PendingActivationData.Feature);
		bool bFaceRight = PlayerTarget.bIsToTheRightOfMe;
		if(!GrabFeature.bThrowingForward)
			bFaceRight = !bFaceRight;

		if(bFaceRight)
			ActivationParams.AddActionState(n"FaceRight");

		SquirrelMeleeComponent.PendingActivationData.Consume(ActivationParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		// This will reset the other attack capability
		SetMutuallyExclusive(MeleeTags::MeleeAttack, true);
		SetMutuallyExclusive(MeleeTags::MeleeAttack, false);
		SquirrelMeleeComponent.SetCanTakeDamage(false);

		FMeleePendingControlData AttackData;
		AttackData.Receive(ActivationParams);
		ActivateState(EHazeMeleeStateType::Attack, AttackData.Feature, AttackData.ActionType);

		if(ActivationParams.GetActionState(n"FaceRight"))
			FaceRightLocal();
		else
			FaceLeftLocal();

		ULocomotionFeaturePlaneFightGrab GrabFeature = Cast<ULocomotionFeaturePlaneFightGrab>(AttackData.Feature);
		if(GrabFeature.bThrowingForward)
			PlayerTarget.SetMeleeAction(MeleeTags::MeleeThrowForward);
		else
			PlayerTarget.SetMeleeAction(MeleeTags::MeleeThrow);
		PlayerTarget.AttachToEnemy(SquirrelMeleeComponent, GrabFeature.AttachBoneName);
		PlayerTarget.ActivateState(EHazeMeleeStateType::HitReaction, ULocomotionFeaturePlaneFightThrown::StaticClass());

		auto TargetPlayer = Game::GetMay();
		if(TargetPlayer.HasControl())
			TargetPlayer.BlockCapabilities(MeleeTags::MeleeBlockedWhenGrabbed, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		DeactivateState(EHazeMeleeStateType::Attack);	
		PlayerTarget.ReleaseCurrentEnemyAttachment();
		SquirrelMeleeComponent.SetCanTakeDamage(true);

		auto TargetPlayer = Game::GetMay();
		if(TargetPlayer.HasControl())
			TargetPlayer.UnblockCapabilities(MeleeTags::MeleeBlockedWhenGrabbed, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		MeleeComponent.UpdateControlSideImpact();
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString Str = "";
		return Str;	
	}

}
