
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeSquirrelComponent;
import Cake.FlyingMachine.Melee.AnimNotify.AnimNotify_MeleeStartDiveAttack;

class UFlyingMachineMeleeSquirrelAttackJumpCapability : UFlyingMachineMeleeCapabilityBase
{
	// default CapabilityTags.Add(CapabilityTags::Movement);
	// default CapabilityTags.Add(FeatureName::Jump);
	// default CapabilityTags.Add(MeleeTags::Melee);
	// default CapabilityTags.Add(MeleeTags::MeleeSquirrelAi);

	// default TickGroup = ECapabilityTickGroups::LastMovement;
	// default TickGroupOrder = 40;

	// default CapabilityDebugCategory = MeleeTags::Melee;

	// /*  EDITABLE VARIABLES */
	// const float ValidDiveDistance = 600.f;
	// /** */

	// UFlyingMachineMeleeSquirrelComponent MeleeComponent;
	// AHazeCharacter Squirrel = nullptr;
	// EHazeMeleeActionInputType CurrentActionType = EHazeMeleeActionInputType::None;
	// bool bShouldDoDiveAttack = false;
	// float TimeLeftToDive = 0;
	// float StopAnimationIn = 0;
	// bool bHasBlockedHitReaction = false;

	// UFUNCTION(BlueprintOverride)
	// void Setup(FCapabilitySetupParams SetupParams)
	// {
	// 	Squirrel = Cast<AHazeCharacter>(Owner);
	// 	MeleeComponent = UFlyingMachineMeleeSquirrelComponent::Get(Squirrel);
	// 	ensure(MeleeComponent != nullptr);
	// }

	// UFUNCTION(BlueprintOverride)
	// void PreTick(float DeltaTime)
	// {	
	
	// }

	// UFUNCTION(BlueprintOverride)
	// EHazeNetworkActivation ShouldActivate() const
	// {
	// 	if(IsActioning(MeleeTags::ValidGrab))
	// 		return EHazeNetworkActivation::DontActivate;
			
	// 	if(!MeleeComponent.AI_ShouldAttack())
	// 		return EHazeNetworkActivation::DontActivate;

	// 	FHazeMelee2DSpineData Spline;
	// 	MeleeComponent.GetSplineData(Spline);
	// 	if(!Spline.bIsGrounded)
	// 		return EHazeNetworkActivation::DontActivate;

	// 	if(MeleeComponent.HasVerticalTranslation())
	// 		return EHazeNetworkActivation::DontActivate;

	// 	if(MeleeComponent.GetHealthAlpha() > 0.6f)
	// 	 	return EHazeNetworkActivation::DontActivate;
		
	// 	if(MeleeComponent.AI_GetAngryness() < 80.f)
	// 		return EHazeNetworkActivation::DontActivate;

	// 	const int RandomNumber = FMath::RandRange(0, 100);
	// 	if(RandomNumber > 33 || MeleeComponent.PlayerTarget.MovementType == EHazeMeleeMovementType::Jumping)
	// 	 	return EHazeNetworkActivation::DontActivate;

	// 	return EHazeNetworkActivation::ActivateFromControl;		
	// }

	// UFUNCTION(BlueprintOverride)
	// EHazeNetworkDeactivation ShouldDeactivate() const
	// {		
	// 	const EHazeMeleeActionInputType CurrentType = GetActionType();
	// 	if(CurrentActionType != CurrentType)
	// 		return EHazeNetworkDeactivation::DeactivateLocal;

	// 	if(GetMovementType() != EHazeMeleeMovementType::Jumping)
	// 		return EHazeNetworkDeactivation::DeactivateLocal;
				
	// 	return EHazeNetworkDeactivation::DontDeactivate;
	// }

	// UFUNCTION(BlueprintOverride)
	// void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	// {	
	// 	if(MeleeComponent.PlayerTarget.bIsToTheRightOfMe)
	// 		FaceRight();
	// 	else
	// 		FaceLeft();

	// 	ActivationParams.AddNumber(n"FacingDir", IsFacingRight() ? 1 : 0);
	// 	//if(FMath::RandBool() || MeleeComponent.PlayerTarget.Distance.X > ValidDiveDistance)
	// 	ActivationParams.AddActionState(n"DiveAttack"); // Always to dive atack for now
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnActivated(FCapabilityActivationParams ActivationParams)
	// {	
	// 	if(!HasControl())
	// 	{
	// 		if(ActivationParams.GetNumber(n"FacingDir") == 1)
	// 			FaceRight();
	// 		else
	// 			FaceLeft();	
	// 	}

	// 	MeleeComponent.SetGravityBlocked(true);

	// 	SetMutuallyExclusive(MeleeTags::MeleeSquirrelAi, true);
	// 	if(!HasControl())
	// 		SetMutuallyExclusive(MeleeTags::MeleeSquirrelAi, false);

	// 	CurrentActionType = EHazeMeleeActionInputType::None;
	// 	SetMovementType(EHazeMeleeMovementType::Jumping, 0.f);
	// 	bShouldDoDiveAttack = ActivationParams.GetActionState(n"DiveAttack");
	// 	bHasBlockedHitReaction = false;
	// 	if(bShouldDoDiveAttack)
	// 	{
	// 		CurrentActionType = EHazeMeleeActionInputType::Punch;
	// 		SetActionInput(EHazeMeleeActionInputType::Punch);
	// 	}
	// 	else
	// 	{
	// 		CurrentActionType = EHazeMeleeActionInputType::Kick;
	// 		SetActionInput(EHazeMeleeActionInputType::Kick);
	// 	}

	// 	ULocomotionFeaturePlaneFightAttack AttackFeature = MeleeComponent.GetAttackFeature();
	// 	ActivateAttackFeature(Squirrel, MeleeComponent, AttackFeature, CurrentActionType);
	// 	TimeLeftToDive = 0;
	// 	Squirrel.SetCapabilityActionState(MeleeTags::MeleeAttack, EHazeActionState::Active);
	// 	if(bShouldDoDiveAttack)
	// 	{
	// 		if(AttackFeature != nullptr)
	// 		{
	// 			const EHazeMeleeAnimationType FaceDir = IsFacingRight() ? EHazeMeleeAnimationType::Right : EHazeMeleeAnimationType::Left;
	// 			TArray<float> TriggerTimes;
	// 			if(AttackFeature.GetAnimation(FaceDir).GetAnimNotifyTriggerTimes(UAnimNotify_MeleeStartDiveAttack::StaticClass(), TriggerTimes))
	// 			{
	// 				TimeLeftToDive = TriggerTimes[0];
	// 			}
	// 			else
	// 			{
	// 				TimeLeftToDive = SMALL_NUMBER;
	// 			}
	// 		}
	// 	}
	// 	else
	// 	{
	// 		const float TravelDistance = MeleeComponent.PlayerTarget.Distance.X;
	// 		MeleeComponent.ActivateHorizontalTranslation(TravelDistance, MeleeComponent.ForwardSpeed * 2.f, !IsFacingRight(), true);
	// 	}

	// 	if(AttackFeature.SpecialAttackType == ESpecialAttackType::SquirrelUnbreakable)
	// 	{
	// 		MeleeComponent.SetUnbreakAbleAttackStatus(Squirrel, EHazeActionState::Active);
	// 	}
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	// {
	// 	if(HasControl())
	// 		SetMutuallyExclusive(MeleeTags::MeleeSquirrelAi, false);

	// 	if(GetMovementType() == EHazeMeleeMovementType::Jumping)
	// 	{
	// 		SetMovementType(EHazeMeleeMovementType::Idling);
	// 		ConditionalStopAnimation(MeleeComponent);
	// 	}
		
	// 	Squirrel.SetCapabilityActionState(MeleeTags::MeleeAttack, EHazeActionState::Inactive);
	// 	MeleeComponent.SetGravityBlocked(false);
	// 	MeleeComponent.AI_OnAttackTriggered();
	// 	MeleeComponent.ClearHorizontalTranslation();
	// 	StopAnimationIn = 0;
	// 	MeleeComponent.SetUnbreakAbleAttackStatus(Squirrel, EHazeActionState::Inactive);
	// 	if(bHasBlockedHitReaction)
	// 	{
	// 		bHasBlockedHitReaction = false;
	// 		Squirrel.UnblockCapabilities(MeleeTags::MeleeHitReaction, this);
	// 	}			
	// }

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	MeleeComponent.ConditionallySendControlImpact(MeleeComponent.PlayerTarget);

	// 	if(HasControl())
	// 	{
	// 		FHazeMelee2DSpineData Spline;
	// 		MeleeComponent.GetSplineData(Spline);
		
	// 		if(StopAnimationIn > 0.f)
	// 		{
	// 			StopAnimationIn -= DeltaTime;
	// 			if(StopAnimationIn <= 0)
	// 			{
	// 				ConditionalStopAnimation(MeleeComponent, 0.2f, true);
	// 			}
	// 		}

	// 		if(!bShouldDoDiveAttack)
	// 		{
	// 			if(MeleeComponent.HasHitTarget())
	// 			{
	// 				MeleeComponent.ClearHorizontalTranslation();
	// 				StopAnimationIn = 0.2f;
	// 			}

	// 			if(MeleeComponent.PlayerTarget.bIsToTheRightOfMe)
	// 				FaceRight();
	// 			else
	// 				FaceLeft();
	// 		}
	// 		else if(TimeLeftToDive > 0)
	// 		{
	// 			TimeLeftToDive -= DeltaTime;
	// 			if(TimeLeftToDive <= 0)
	// 			{		
	// 				const float TravelDistance = FMath::Max(MeleeComponent.PlayerTarget.Distance.X - 100.f, 0.f);
	// 				if(TravelDistance > 0)
	// 				{
	// 					MeleeComponent.ActivateHorizontalTranslation(TravelDistance, TravelDistance / 0.3f, !IsFacingRight(), true);
	// 					bHasBlockedHitReaction = true;
	// 					Squirrel.BlockCapabilities(MeleeTags::MeleeHitReaction, this);
	// 				}		
	// 			}
	// 		}

	// 		FHazeLocomotionTransform RootMotion;
	// 		Squirrel.RequestRootMotion(DeltaTime, RootMotion);
	// 		MeleeComponent.AddDeltaMovement(n"JumpAttack", 0.f, RootMotion.DeltaTranslation.Z);
	// 	}
		
	// 	//SendMovementAnimationRequest(Squirrel, MeleeComponent, n"Movement");
	// }

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString Str = "";
		return Str;	
	}
}
