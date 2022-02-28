import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;

enum ESickleAttackValidationGroundedType
{
	Any,
	Grounded,
	Flying
}

enum ESickleAttackTranslationType
{
	DoNothing,
	TranslateToTarget,
	ApplySmallUpForce
}


struct FSickleAttackValidationCompareData
{
	UPROPERTY(BlueprintReadOnly)
	int WantedComboNumber = 1;

	UPROPERTY(BlueprintReadOnly)
	FName CurrentComboTag = NAME_None;

	UPROPERTY(BlueprintReadOnly)
	bool bPlayerIsGrounded = false;

	UPROPERTY(BlueprintReadOnly)
	bool bHasTarget = false;

	UPROPERTY(BlueprintReadOnly)
	FName TargetNameTag = NAME_None;

	UPROPERTY(BlueprintReadOnly)
	bool bTargetIsGrounded = false;

	UPROPERTY(BlueprintReadOnly)
	bool bTargetIsInvulerable = false;

	UPROPERTY(BlueprintReadOnly)
	float AngleToTarget = 0;

	UPROPERTY(BlueprintReadOnly)
	float DistanceToTarget = 0;
}

// A struct that contains all data from the combo request
struct FSickleAttackValidationData
{
	// If we require a combo count to activate
	UPROPERTY(meta = (InlineEditConditionToggle))
	bool bRequiresComboNumber = true;

	// The combo index required to activate
	UPROPERTY(meta = (ClampMin = "1", EditCondition = "bRequiresComboNumber"))
	int ComboNumber = 1;

	// The grounded state required for the player to trigger
	UPROPERTY()
	ESickleAttackValidationGroundedType PlayerIsGrounded = ESickleAttackValidationGroundedType::Any;

	// The Current active combo tag required to trigger if not None.
	UPROPERTY()
	FName ComboTag = NAME_None;

	// If we require a valid target to trigger
	UPROPERTY()
	bool bRequiresTarget = false;

	UPROPERTY(meta = (EditCondition = "bRequiresTarget"))
	FSickleAttackTargetValidationData TargetData;

	bool IsValidTo(FSickleAttackValidationCompareData RequestData)
	{
		if(bRequiresComboNumber && RequestData.WantedComboNumber != ComboNumber)
			return false;

		if(PlayerIsGrounded != ESickleAttackValidationGroundedType::Any)
		{
			if(RequestData.bPlayerIsGrounded && PlayerIsGrounded == ESickleAttackValidationGroundedType::Flying)
				return false;
			else if(!RequestData.bPlayerIsGrounded && PlayerIsGrounded == ESickleAttackValidationGroundedType::Grounded)
				return false;
		}

		if(ComboTag != NAME_None)
		{
			if(RequestData.CurrentComboTag != ComboTag)
				return false;
		}

		if(bRequiresTarget != RequestData.bHasTarget)
			return false;
	
		if(RequestData.bHasTarget)
		{
			if(TargetData.bUseInvulerableValidation)
			{
				if(TargetData.bRequiresInvulerableTarget != RequestData.bTargetIsInvulerable)
					return false;
			}

			if(TargetData.TargetNameTag != NAME_None)
			{
				if(RequestData.TargetNameTag != TargetData.TargetNameTag)
					return false;
			}

			if(TargetData.bRequiresTargetDistance)
			{
				if(TargetData.TargetDistance.Min > 0 && RequestData.DistanceToTarget <= TargetData.TargetDistance.Min)
					return false;

				if(TargetData.TargetDistance.Max > 0 && RequestData.DistanceToTarget >= TargetData.TargetDistance.Max)
					return false;
			}

			if(TargetData.bRequiresTargetAngle)
			{
				if(!TargetData.AngleToTarget.IsInsideRange(RequestData.AngleToTarget))
					return false;
			}
	
			if(TargetData.TargetIsGrounded != ESickleAttackValidationGroundedType::Any)
			{
				if(RequestData.bTargetIsGrounded && TargetData.TargetIsGrounded == ESickleAttackValidationGroundedType::Flying)
					return false;

				else if(!RequestData.bTargetIsGrounded && TargetData.TargetIsGrounded == ESickleAttackValidationGroundedType::Grounded)
					return false;
			}
		}

		return true;
	}
}

// A struct that contains all data from the combo request
struct FSickleAttackTargetValidationData
{
	UPROPERTY(meta = (InlineEditConditionToggle))
	bool bUseInvulerableValidation = false;

	// If the attack should trigger on Invulnerable targets
	UPROPERTY(meta = (EditCondition = "bUseInvulerableValidation"))
	bool bRequiresInvulerableTarget = false;

	// The grounded state required for the target to trigger
	UPROPERTY()
	ESickleAttackValidationGroundedType TargetIsGrounded = ESickleAttackValidationGroundedType::Any;

	UPROPERTY(BlueprintReadOnly, meta = (InlineEditConditionToggle))
	bool bRequiresTargetDistance = false;

	// The distance range required to trigger
	UPROPERTY(BlueprintReadOnly, meta = (EditCondition = "bRequiresTargetDistance", ClampMin = "0.0"))
	FHazeMinMax TargetDistance;

	UPROPERTY(BlueprintReadOnly, meta = (InlineEditConditionToggle))
	bool bRequiresTargetAngle = false;

	// The angle to the target reguired to trigger
	UPROPERTY(meta = (EditCondition = "bRequiresTargetAngle"))
	FHazeMinMax AngleToTarget;

	// The Current target tag required to trigger.
	UPROPERTY()
	FName TargetNameTag = NAME_None;
}

UCLASS(hidecategories="ABP")
class USickleAttackDataDamageAsset : UDataAsset
{
	UPROPERTY()
	bool bRandomDamage = false;

	UPROPERTY()
	float Damage = 10;

	UPROPERTY(meta = (EditCondition = "bRandomDamage", EditConditionHides))
	float MaxDamage = 10;
}

// The data asset base class
UCLASS(hidecategories="ABP")
class USickleAttackDataAsset : UHazeLocomotionFeatureBase
{
	default Tag = n"SickleAttack";
	default bReInitAnimWhenRequested = true;
	default AttackAnimation.BlendTime = 0;

	float GetDamage()const
	{
		if(DamageAsset == nullptr)
			return 0;

		if(DamageAsset.bRandomDamage)
		{
			return FMath::RandRange(DamageAsset.Damage, DamageAsset.MaxDamage);
		}
		else
		{
			return DamageAsset.Damage;
		}
	}

	UPROPERTY(Category = "Combo Data")
	FName ComboTag = n"RenameMe";

	// How long time after the attack has finished will the combo counter reset
	UPROPERTY(Category = "Combo Data")
	float TimeBeforeComboCounterReset = 0.27f;

	UPROPERTY(Category = "Combo Validation")
	FSickleAttackValidationData Validation;


	UPROPERTY(Category = "Movement")
	ESickleAttackTranslationType MovementTranslationType = ESickleAttackTranslationType::TranslateToTarget;

	UPROPERTY(Category = "Movement")
	bool bForceApplyGravity = false;

	UPROPERTY(Category = "Movement", meta = (EditCondition = "MovementTranslationType == ESickleAttackTranslationType::TranslateToTarget", EditConditionHides, DisplayName = "TranslateToTargetTime"))
	float TranslateToTagetTime = 0.2f;

	UPROPERTY(Category = "Movement", meta = (EditCondition = "MovementTranslationType == ESickleAttackTranslationType::TranslateToTarget", EditConditionHides))
	FRuntimeFloatCurve TranslationCruve;

	UPROPERTY(Category = "Movement", meta = (EditCondition = "MovementTranslationType == ESickleAttackTranslationType::ApplySmallUpForce", EditConditionHides))
	float UpForce = 0;

	UPROPERTY(Category = "Attack Damage")
	USickleAttackDataDamageAsset DamageAsset = nullptr;

	UPROPERTY(Category = "Attack Knockback")
	float AttackKnockbackVerticalForce = 1.f;
	
	UPROPERTY(Category = "Attack Knockback")
	float AttackKnockbackHorizontalForce = 7.f;

	UPROPERTY(Category = "Animation")
	FHazePlaySlotAnimationParams AttackAnimation;
}


