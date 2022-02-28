
class ULocomotionFeaturePlaneFightAttackBase: ULocomotionFeatureMeleeFightAttack
{
    default PlayerValidation.RequiredInputHistory.Add(MeleeInput::MakeAction(EHazeMeleeActionInputType::Punch));
	default Tag = n"MeleeAttack";
	default bReInitAnimWhenRequested = true;

	// This moves combotag. Use to evaluate the 'RequiredComboMoveTag'.
    UPROPERTY(Category = "Attack")
    FName ComboMoveTag = NAME_None;

	UPROPERTY(Category = "Validation")
	bool bIsPlayerValidation = true;

    // This will sort out what kind of animations that will trigger. Only valid if >= 0
    UPROPERTY(Category = "Validation")
    float TriggerMinRange = -1;

     // This will sort out what kind of animations that will trigger. Only valid if >= 0
    UPROPERTY(Category = "Validation")
    float TriggerMaxRange = -1;

	 UPROPERTY(Category = "Validation")
	float TriggerMaxRangePlayerVelocityBonusAmount = 0;

	// The amount the character moves when this attack is triggered
	UPROPERTY(Category = "Translation")
	float HorizontalTranslationAmount = 0;

	// The amount movespeed.
	UPROPERTY(Category = "Translation", meta = (EditCondition = "!bIsPlayerValidation"))
	float HorizontalTranslationMoveSpeed = 0;

	// Player Validation
	UPROPERTY(Category = "Validation", meta = (EditCondition = "bIsPlayerValidation", EditConditionHides))
	FHazeMeleeAttackPlayerValidation PlayerValidation;


	// AI Validation
	UPROPERTY(Category ="Attack", meta = (EditCondition = "!bIsPlayerValidation"))
    EHazeMeleeActionInputType AiAction = EHazeMeleeActionInputType::Punch;

	UPROPERTY(Category = "Validation", meta = (EditCondition = "!bIsPlayerValidation", EditConditionHides))
	FHazeMeleeAttackAiValidation AiValidation;
};

class ULocomotionFeaturePlaneFightAttack: ULocomotionFeaturePlaneFightAttackBase
{
	default Tag = n"MeleeAttack";
}

class ULocomotionFeaturePlaneFightAttackShootNut: ULocomotionFeaturePlaneFightAttackBase
{
	default Tag = n"MeleeAttackNut";
};

class ULocomotionFeaturePlaneFightAttackRush: ULocomotionFeaturePlaneFightAttackBase
{
	default Tag = n"MeleeAttack";

	UPROPERTY(Category = "Validation")
	float MaxEdgeDistance = 0;

	UPROPERTY(Category = "Validation")
	int MaxRushTimes = 0;
};

class ULocomotionFeaturePlaneFightGrab: ULocomotionFeaturePlaneFightAttackBase
{
	default Tag = n"MeleeAttackGrab";
    
	UPROPERTY(Category = "Animation")
	bool bThrowingForward = true;

	UPROPERTY(Category = "Animation")
	FName AttachBoneName = NAME_None;

};


enum EHazeMeleeComboCountCompareType
{
	NotUsed,
	GreaterOrEqual,
	Equal,
	LessThenOrEqual
};

struct FHazeMeleeAttackPlayerValidation
{
	UPROPERTY()
	EHazeMeleeComboCountCompareType RequiredComboCountType = EHazeMeleeComboCountCompareType::NotUsed;

	UPROPERTY(meta = (EditCondition="RequiredComboCountType != EHazeMeleeComboCountCompareType::NotUsed", EditConditionHides))
    int RequiredComboCount = 0;

	UPROPERTY(meta = (EditCondition="RequiredComboCountType != EHazeMeleeComboCountCompareType::NotUsed", EditConditionHides))
	TArray<EHazeMeleeActionInputType> AnyRequiredComboActionTypes;

		// All has to be valid. Index 0 is the most recent...
	UPROPERTY(meta = (ShowOnlyInnerProperties))
	TArray<FHazeMeleeRequiredInput> RequiredInputHistory;

	// A previus tag that is required for this to be valid
	UPROPERTY()
	FName RequiredComboMoveTag = NAME_None;

	// Valid if not nullptr.
	UPROPERTY()
	ULocomotionFeaturePlaneFightAttackBase RequiredComboFeature = nullptr;
}

enum EAiAttackType
{
	Any,
	AttackLow,
	AttackMid,
	AttackHigh,
	MAX
}

struct FHazeMeleeAttackAiValidation
{
	UPROPERTY()
	TArray<EAiAttackType> AnyWantedType;

	UPROPERTY()
	EHazeMeleeComboCountCompareType RequiredAiLevel = EHazeMeleeComboCountCompareType::NotUsed;

	UPROPERTY(meta = (EditCondition="RequiredAiLevel != EHazeMeleeComboCountCompareType::NotUsed", EditConditionHides))
	EHazeMeleeLevelType AiLevel;

	// How long time must have passed since this move was last used
	UPROPERTY()
	float CooldownTime = 0;

	UPROPERTY()
	TArray<EAiAttackType> LastAttackWasAnyOfTheese;
}

