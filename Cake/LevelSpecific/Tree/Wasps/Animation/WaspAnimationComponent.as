import Cake.LevelSpecific.Tree.Wasps.Animation.LocomotionFeatureHeroWasp;
import Cake.LevelSpecific.Tree.Wasps.Animation.LocomotionFeatureWaspShooting;

class UWaspAnimationComponent : UActorComponent
{
    AHazeCharacter CharOwner = nullptr;
    ULocomotionFeatureHeroWasp AnimFeature = nullptr;
	ULocomotionFeatureHeroWasp DefaultAnimFeature =	Asset("/Game/Blueprints/LevelSpecific/Tree/AI/Wasps/DA_CommonFeature_Wasp.DA_CommonFeature_Wasp");

	UPROPERTY()
	ULocomotionFeatureWaspShooting ShootingAnimFeature = nullptr;

	UPROPERTY(NotVisible, BlueprintReadWrite)
	USceneComponent WeaponComp = nullptr;

	UPROPERTY(NotVisible, BlueprintReadWrite)
	USceneComponent ArmourComp = nullptr;

	UPROPERTY(NotVisible, BlueprintReadWrite)
	USceneComponent ShieldComp = nullptr;

	// These values are not replicated, capabilities using this should make sure we play the same variants on both sides
	EWaspAnim CurrentAnim = EWaspAnim::None;
	uint8 CurrentVariant = 0;
	float StartBlendTime = 0.2f;	
	float EndBlendTime = 0.2f;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CharOwner = Cast<AHazeCharacter>(GetOwner());
        AnimFeature = ULocomotionFeatureHeroWasp::Get(CharOwner);
		if (AnimFeature == nullptr)
			AnimFeature = DefaultAnimFeature; // HACK to compensate for broken ULocomotionFeatureHeroWasp::Get
		if (WeaponComp != nullptr)
			WeaponComp.AddTickPrerequisiteComponent(CharOwner.Mesh);
		if (ArmourComp != nullptr)
			ArmourComp.AddTickPrerequisiteComponent(CharOwner.Mesh);
		if (ShieldComp != nullptr)
			ShieldComp.AddTickPrerequisiteComponent(CharOwner.Mesh);

        ensure(AnimFeature != nullptr);
	}

	UFUNCTION()
	void Reset()
	{
		CurrentAnim = EWaspAnim::None;
		CurrentVariant = 0;
		StartBlendTime = 0.2f;	
		EndBlendTime = 0.2f;

		if (ArmourComp != nullptr)
			ArmourComp.SetHiddenInGame(false);
		if (ShieldComp != nullptr)
			ShieldComp.SetHiddenInGame(false);
		if (WeaponComp != nullptr)
			WeaponComp.SetHiddenInGame(false);
	}

	void PlayAnimation(EWaspAnim Anim, float BlendTime = 0.2f)
	{
		PlayAnimation(Anim, 0, BlendTime);
	}
	void PlayAnimation(EWaspAnim Anim, uint8 Variant, float BlendTime = 0.2f)
	{
#if EDITOR
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool) Print("Wasp play animation " + Owner.GetName() + " " + Anim);		
#endif
		CurrentAnim = Anim;
		CurrentVariant = Variant;
		StartBlendTime = BlendTime;
	}

	void StopAnimation(EWaspAnim Anim, float BlendTime = 0.2f)
	{
#if EDITOR
		if (bHazeEditorOnlyDebugBool) Print("Wasp stop animation " + Owner.GetName() + " " + Anim);		
#endif
		if (CurrentAnim == Anim)
			CurrentAnim = EWaspAnim::None;
		EndBlendTime = BlendTime;
	}

	bool ShouldPlaySingleAnimation()
	{
		UAnimSequence SingleAnim = AnimFeature.GetSingleAnimation(CurrentAnim, CurrentVariant);
		if (SingleAnim != nullptr)
			return true;

		if (ShootingAnimFeature != nullptr)
		{
			FWaspShootingAnims ShootAnims = ShootingAnimFeature.GetSingleAnimation(CurrentAnim, CurrentVariant);
			if (ShootAnims.Wasp != nullptr)
				return true;
		}

		// Not a single anim
		return false;
	}

	bool ShouldPlayThreeshotAnimation()
	{
		FWaspThreeShotSequence ThreeShotAnim;
		if (!AnimFeature.GetThreeshotAnimation(CurrentAnim, CurrentVariant, ThreeShotAnim))
			return false;
		if ((ThreeShotAnim.Start == nullptr) && (ThreeShotAnim.MH == nullptr))
			return false;
		return true;
	}
}