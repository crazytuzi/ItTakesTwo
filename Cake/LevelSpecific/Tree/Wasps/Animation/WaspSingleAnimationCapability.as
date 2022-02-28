import Cake.LevelSpecific.Tree.Wasps.Animation.WaspAnimationComponent;
import Cake.LevelSpecific.Tree.Wasps.Animation.LocomotionFeatureHeroWasp;
import Cake.LevelSpecific.Tree.Wasps.Animation.LocomotionFeatureWaspShooting;
import Cake.LevelSpecific.Tree.Wasps.Settings.WaspComposableSettings;

class UWaspSingleAnimationCapability : UHazeCapability
{
    default CapabilityTags.Add(n"WaspAnimation");
	default TickGroup = ECapabilityTickGroups::AfterGamePlay; // After behaviours

	UWaspAnimationComponent AnimComp;
	EWaspAnim PlayingAnim = EWaspAnim::None;
	uint8 PlayingVariant = 0;
	bool bStartingAnim = false;
	UWaspComposableSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        // Set common references 
		AnimComp = UWaspAnimationComponent::Get(Owner);
		Settings = UWaspComposableSettings::GetSettings(Owner);
        ensure((AnimComp != nullptr) && (Settings != nullptr));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!AnimComp.ShouldPlaySingleAnimation())
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (AnimComp.CurrentAnim != PlayingAnim)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (AnimComp.CurrentVariant != PlayingVariant)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayingAnim = AnimComp.CurrentAnim;
		PlayingVariant = AnimComp.CurrentVariant;
		UAnimSequence Anim = AnimComp.AnimFeature.GetSingleAnimation(PlayingAnim, PlayingVariant);
		float BlendTime = AnimComp.StartBlendTime;
		FHazeAnimationDelegate OnAnimDone;
		OnAnimDone.BindUFunction(this, n"OnAnimDone");

		bStartingAnim = true;
		if (Anim != nullptr)
		{
			// Normal animation
			float HackPlayRate = (PlayingAnim == EWaspAnim::Taunts) ? Settings.TauntHackTimeScaling : 1.f;
			Owner.PlaySlotAnimation(Animation = Anim, BlendTime = BlendTime, OnBlendingOut = OnAnimDone, PlayRate = HackPlayRate);   
		}
		else 
		{
			// Check if shooting animation
			FWaspShootingAnims ShootingAnims;
			if (AnimComp.ShootingAnimFeature != nullptr)
				ShootingAnims = AnimComp.ShootingAnimFeature.GetSingleAnimation(PlayingAnim, PlayingVariant);
			if (ShootingAnims.Wasp != nullptr)
			{
				Owner.PlaySlotAnimation(Animation = ShootingAnims.Wasp, BlendTime = BlendTime, OnBlendingOut = OnAnimDone);   
				UHazeSkeletalMeshComponentBase Weapon = Cast<UHazeSkeletalMeshComponentBase>(AnimComp.WeaponComp);
				if (Weapon != nullptr)
				{
					FHazePlaySlotAnimationParams Params;
					Params.Animation = ShootingAnims.Weapon;
					Params.BlendTime = BlendTime;
					Weapon.PlaySlotAnimation(Params);
				}
			}
			else // Could not find anim, should not happen!
			{
				ensure(false);
				AnimComp.StopAnimation(PlayingAnim);
			}
		}
		bStartingAnim = false;
    }
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Stop animation if still playing
		UAnimSequence Anim = AnimComp.AnimFeature.GetSingleAnimation(PlayingAnim, PlayingVariant);
		if (Owner.IsPlayingAnimAsSlotAnimation(Anim))
		{
			Owner.StopAnimationByAsset(Anim, BlendTime = AnimComp.EndBlendTime);
		}
		else if (AnimComp.ShootingAnimFeature != nullptr)
		{
			FWaspShootingAnims ShootingAnims = AnimComp.ShootingAnimFeature.GetSingleAnimation(PlayingAnim, PlayingVariant);
			if ((ShootingAnims.Wasp != nullptr) && Owner.IsPlayingAnimAsSlotAnimation(ShootingAnims.Wasp))
				Owner.StopAnimationByAsset(ShootingAnims.Wasp, BlendTime = AnimComp.EndBlendTime);
			if (ShootingAnims.Weapon != nullptr)
			{
				UHazeSkeletalMeshComponentBase Weapon = Cast<UHazeSkeletalMeshComponentBase>(AnimComp.WeaponComp);
				if ((Weapon != nullptr) && Weapon.IsPlayingAnimAsSlotAnimation(ShootingAnims.Weapon))
				{
					FHazeStopSlotAnimationByAssetParams Params;
					Params.Animation = ShootingAnims.Weapon;
					Params.BlendTime = AnimComp.EndBlendTime;
					Weapon.StopSlotAnimationByAsset(Params);
				}
			} 
		}
	}

	UFUNCTION()
	void OnAnimDone()
	{
		if (IsActive() && (PlayingAnim == AnimComp.CurrentAnim) && (PlayingVariant == AnimComp.CurrentVariant))
		{
			if (!bStartingAnim)
				AnimComp.StopAnimation(PlayingAnim);
		}
	}
}
