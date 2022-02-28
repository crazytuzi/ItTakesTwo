
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeSquirrelComponent;

class UFlyingMachineMeleeSquirrelHangCapability : UFlyingMachineMeleeCapabilityBase
{
	// default CapabilityTags.Add(CapabilityTags::Movement);
	// default CapabilityTags.Add(MeleeTags::Melee);
	// default CapabilityTags.Add(MeleeTags::MeleeSquirrelAi);
	// default CapabilityTags.Add(MeleeTags::MeleeAttack);
	
	// default TickGroup = ECapabilityTickGroups::BeforeMovement;

	// default CapabilityDebugCategory = MeleeTags::Melee;

	// default TickGroupOrder = 80;

	// UPROPERTY()
	// FVector TargetOffest = FVector(225.f, 0.f, -30.f);

	// const float EdgeDistance = 300.f;

	// AHazeCharacter Squirrel = nullptr;
	// UFlyingMachineMeleeSquirrelComponent MeleeComponent;

	// float ReleaseTimeLeft = 0;
	// float MaxReleaseTime = 0;
	// float ExitTimeLeft = 0;
	// float TranslationLeftToConsume = 0;
	// float MoveDir = 1.f;
	// bool bIsAttacking = false;

	// FVector CurrentOffset = FVector::ZeroVector;
	// float CanActivateTime = 0;

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
	// 	if(GetActionType() == EHazeMeleeActionInputType::HitReaction)
	// 		CanActivateTime = 0.5f;
	// 	else
	// 		CanActivateTime = FMath::Max(CanActivateTime - DeltaTime, 0.f);
	// }

	// UFUNCTION(BlueprintOverride)
	// EHazeNetworkActivation ShouldActivate() const
	// {
	// 	if(!MeleeComponent.AI_ShouldAttack())
	// 		return EHazeNetworkActivation::DontActivate;

	// 	if(CanActivateTime <= 0)
	// 		return EHazeNetworkActivation::DontActivate; 

	// 	FHazeMelee2DSpineData SplineData;
	// 	MeleeComponent.GetSplineData(SplineData);
	// 	const bool bFacingRight = IsFacingRight();

	// 	if(MeleeComponent.PlayerTarget.Distance.X > 320.f)
	// 		return EHazeNetworkActivation::DontActivate;

	// 	if((SplineData.SplinePosition.X < EdgeDistance && !bFacingRight) 
	// 		|| (SplineData.SplinePosition.X > SplineData.SplineLength - EdgeDistance && bFacingRight))
	// 	{
	// 		return EHazeNetworkActivation::ActivateFromControl;	
	// 	}

	// 	return EHazeNetworkActivation::DontActivate;
	// }

	// UFUNCTION(BlueprintOverride)
	// EHazeNetworkDeactivation ShouldDeactivate() const
	// {
	// 	if(ReleaseTimeLeft <= 0.f && GetActionType() != EHazeMeleeActionInputType::Punch)
	// 		return EHazeNetworkDeactivation::DeactivateFromControl;

	// 	return EHazeNetworkDeactivation::DontDeactivate;
	// }

	// UFUNCTION(BlueprintOverride)
	// void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	// {
	// 	const float AttackDistance = 50.f;

	// 	FHazeMelee2DSpineData Spline;
	// 	MeleeComponent.GetSplineData(Spline);
	// 	const float SplineMid = Spline.SplineLength * 0.5f;
	// 	const float SplineMidDist = Spline.SplinePosition.X - SplineMid;
	// 	const float PlayerDist = MeleeComponent.PlayerTarget.RelativeLocation.X * 0.5f;
	// 	if(FMath::Abs(SplineMidDist) > FMath::Abs(PlayerDist))
	// 		ActivationParams.AddValue(n"OffsetAmount", SplineMidDist);
	// 	else
	// 		ActivationParams.AddValue(n"OffsetAmount", PlayerDist);
	// 	ActivationParams.AddValue(n"ReleaseTime", FMath::RandRange(0.25f, 0.5f));
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnActivated(FCapabilityActivationParams ActivationParams)
	// {	
	// 	MeleeComponent.ClearVerticalTranslation();
	// 	SetMutuallyExclusive(MeleeTags::MeleeSquirrelAi, true);
	// 	Squirrel.BlockCapabilities(FeatureName::Jump, this);
	// 	if(!HasControl())
	// 	{
	// 		SetMutuallyExclusive(MeleeTags::MeleeSquirrelAi, false);
	// 		Squirrel.UnblockCapabilities(FeatureName::Jump, this);
	// 	}

	// 	bIsAttacking = false;	
		
	// 	SetMovementType(EHazeMeleeMovementType::Hanging, 0.f);
	
	// 	TranslationLeftToConsume = ActivationParams.GetValue(n"OffsetAmount");
	// 	MoveDir = -1.f;
	// 	if(TranslationLeftToConsume < 0)
	// 	{
	// 		TranslationLeftToConsume = -TranslationLeftToConsume;
	// 		MoveDir = 1.f;
	// 	}
	// 	MaxReleaseTime = FMath::Max(ActivationParams.GetValue(n"ReleaseTime"), SMALL_NUMBER);
	// 	ReleaseTimeLeft = MaxReleaseTime;
	// 	SetActiveActionType(EHazeMeleeActionInputType::None);

	// 	ULocomotionFeaturePlaneFightHang Feature = MeleeComponent.GetHangFeature();
	// 	if(Feature != nullptr)
	// 	{
	// 		ActivateFeature(Squirrel, MeleeComponent, Feature, Feature.BlendIn, EHazeMeleeActionInputType::Special);
	// 	}


	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	// {
	// 	if(HasControl())
	// 	{
	// 		SetMutuallyExclusive(MeleeTags::MeleeSquirrelAi, false);
	// 		Squirrel.UnblockCapabilities(FeatureName::Jump, this);
	// 	}
	
	// 	SetMovementType(EHazeMeleeMovementType::Idling);
	// 	Squirrel.Mesh.SetRelativeLocation(FVector::ZeroVector);
	// 	MeleeComponent.AI_OnAttackTriggered();
	// }

	// UFUNCTION(BlueprintOverride)
	// void NotificationReceived(FName Notification, FCapabilityNotificationReceiveParams NotificationParams)
	// {
	// 	if(Notification == n"HangAttack")
	// 	{
	// 		if(MeleeComponent.PlayerTarget.bIsToTheRightOfMe)
	// 			FaceRight();
	// 		else
	// 			FaceLeft();

	// 		ReleaseTimeLeft = 0;
	// 		bIsAttacking = true;
	// 		ULocomotionFeaturePlaneFightAttack Feature = MeleeComponent.GetAttackFeature(MeleeComponent.GetActiveComboTag());
	// 		if(Feature != nullptr)
	// 		{
	// 			ActivateAttackFeature(Squirrel, MeleeComponent, Feature, EHazeMeleeActionInputType::Punch);
	// 		}
	// 	}
	// }

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {	
	// 	if(GetActionType() == EHazeMeleeActionInputType::None)
	// 	{
	// 		float MoveAmount = FMath::Min(200.f * DeltaTime, TranslationLeftToConsume);
	// 		TranslationLeftToConsume -= MoveAmount;
	// 		if(HasControl())
	// 			MeleeComponent.AddDeltaMovement(n"Hanging", -MoveAmount * Squirrel.GetActorRelativeScale3D().X * MoveDir, 0.f);
	// 		CurrentOffset = FMath::VInterpConstantTo(CurrentOffset, TargetOffest, DeltaTime, 300.f);			
	// 	}
	// 	else if(GetActionType() == EHazeMeleeActionInputType::Special)
	// 	{
	// 		CurrentOffset = FMath::VInterpConstantTo(CurrentOffset, TargetOffest, DeltaTime, 300.f);
	// 	}

	// 	if(MeleeComponent.PlayerTarget.Distance.X < 50.f)
	// 	{
	// 		FHazeMelee2DSpineData Spline;
	// 		MeleeComponent.GetSplineData(Spline);
	// 		if(Spline.SplinePosition.X > EdgeDistance && Spline.SplinePosition.X < Spline.SplineLength - 300)
	// 			TranslationLeftToConsume = 0.f;
	// 	}
			

	// 	if(TranslationLeftToConsume <= 0)
	// 	{
	// 		if(ReleaseTimeLeft > 0)
	// 		{
	// 			ReleaseTimeLeft -= DeltaTime;
	// 			CurrentOffset = FMath::VInterpConstantTo(CurrentOffset, TargetOffest, DeltaTime, 300.f);
	// 			if(ReleaseTimeLeft <= 0)
	// 			{
	// 				TriggerNotification(n"HangAttack");
	// 			}
	// 		}
	// 		else
	// 		{
	// 			CurrentOffset = FMath::VInterpConstantTo(CurrentOffset, FVector::ZeroVector, DeltaTime, 300.f);
	// 			MeleeComponent.ConditionallySendControlImpact(MeleeComponent.PlayerTarget);
	// 		}
	// 	}
	// 	else
	// 	{
	// 		//SendMovementAnimationRequest(Squirrel, MeleeComponent, n"Movement");
	// 	}

	// 	if(bIsAttacking)
	// 	{
	// 		MeleeComponent.ConditionallySendControlImpact(MeleeComponent.PlayerTarget);
	// 	}

	// 	Squirrel.Mesh.SetRelativeLocation(CurrentOffset);
	//}

	// UFUNCTION(BlueprintOverride)
	// FString GetDebugString()
	// {
	// 	FHazeMelee2DSpineData SplineData;
	// 	MeleeComponent.GetSplineData(SplineData);

	// 	FString Str = "";

	// 	Str += "TranslationLeftToConsume: " + TranslationLeftToConsume + "\n";
	// 	Str += "Distance: " + FMath::Abs((SplineData.SplineLength * 0.5f) - SplineData.SplinePosition.X) + "\n";
	// 	Str += "ReleaseTimeLeft: " + ReleaseTimeLeft + "\n";
	// 	return Str;	
	// }
}
