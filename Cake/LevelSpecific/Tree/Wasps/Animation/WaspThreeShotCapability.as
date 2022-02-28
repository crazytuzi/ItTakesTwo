import Cake.LevelSpecific.Tree.Wasps.Animation.WaspAnimationComponent;

class UWaspThreeShotAnimationCapability : UHazeCapability
{
    default CapabilityTags.Add(n"WaspAnimation");
    default CapabilityTags.Add(n"WaspAnimationThreeShot");
	default TickGroup = ECapabilityTickGroups::AfterGamePlay; // After behaviours

	UWaspAnimationComponent AnimComp;
	EWaspAnim PlayingAnim = EWaspAnim::None;
	uint8 PlayingVariant = 0;
	FWaspThreeShotSequence ThreeShot;
	float EndBlendTime = 0.2f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        // Set common references 
		AnimComp = UWaspAnimationComponent::Get(Owner);
        ensure(AnimComp != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!AnimComp.ShouldPlayThreeshotAnimation())
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
		if (ensure(AnimComp.AnimFeature.GetThreeshotAnimation(PlayingAnim, PlayingVariant, ThreeShot)))
		{
			if (ThreeShot.Start != nullptr)
			{
				// Play start then go to mh
				FHazeAnimationDelegate OnAnimDone;
				OnAnimDone.BindUFunction(this, n"OnStartAnimDone");
				Owner.PlaySlotAnimation(OnBlendingOut = OnAnimDone, Animation = ThreeShot.Start, BlendTime = AnimComp.StartBlendTime);   
			}
			else 
			{
				// Directly into mh
				Owner.PlaySlotAnimation(Animation = ThreeShot.MH, BlendTime = AnimComp.StartBlendTime, bLoop = true);   
			}
		}
		else // Could not find anim, should not happen!
			AnimComp.StopAnimation(PlayingAnim);
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (Owner.IsPlayingAnimAsSlotAnimation(ThreeShot.MH) || 
		    Owner.IsPlayingAnimAsSlotAnimation(ThreeShot.Start))
		{
			if (ThreeShot.End != nullptr)
        		Owner.PlaySlotAnimation(Animation = ThreeShot.End, BlendTime = AnimComp.EndBlendTime);   
			else
			{
				Owner.StopAnimationByAsset(ThreeShot.Start, BlendTime = AnimComp.EndBlendTime);
				Owner.StopAnimationByAsset(ThreeShot.MH, BlendTime = AnimComp.EndBlendTime);
			}
		}
	}

	UFUNCTION()
	void OnStartAnimDone()
	{
		if (IsActive())
	        Owner.PlaySlotAnimation(Animation = ThreeShot.MH, BlendTime = 0.f, bLoop = true);   
	}
}