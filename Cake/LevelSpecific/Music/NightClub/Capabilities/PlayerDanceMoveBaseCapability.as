import Cake.LevelSpecific.Music.NightClub.RhythmActor;
import Cake.LevelSpecific.Music.NightClub.RhythmTempoActor;

UCLASS(abstract)
class UPlayerDanceMoveBaseCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 20;

	AHazePlayerCharacter Player;
	UPlayerRhythmComponent RhythmComp;

	FName DanceActionName = NAME_None;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		RhythmComp = UPlayerRhythmComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(RhythmComp.RhythmDanceArea == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!RhythmComp.bIsDancing)
			return EHazeNetworkActivation::DontActivate;

		if(!WasActionStarted(DanceActionName))
			return EHazeNetworkActivation::DontActivate;

		if(HasControl() && !RhythmComp.RhythmDanceArea.HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	void Internal_ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams, TSubclassOf<ARhythmTempoActor> TempoActorClass)
	{
		ARhythmTempoActor TempoActor = RhythmComp.RhythmDanceArea.TestTempo(TempoActorClass);

		if(TempoActor != nullptr)
		{
			ActivationParams.AddActionState(n"TempoHit");
			RhythmComp.RhythmDanceArea.OnTempoHit(TempoActor);
		}
		else
		{
			// We get here if we failed to hit a tempo.
			if(RhythmComp.DanceFailCooldown <= 0.0f)
			{
				ActivationParams.AddActionState(n"FailTempo");
			}
		}
	}

	void Internal_OnActivated(FCapabilityActivationParams& ActivationParams, bool& bHit)
	{
		bool bTempoHit = ActivationParams.GetActionState(n"TempoHit");

		if(bTempoHit)
		{
			bHit = true;
			Player.PlayForceFeedback(RhythmComp.SuccessForceFeedback, false, true, n"DanceSuccess");

			if(Player.IsPlayingAnyAnimationOnSlot(EHazeSlotAnimType::SlotAnimType_Default))
				Player.StopAllSlotAnimations();
		}
		else if(ActivationParams.GetActionState(n"FailTempo"))
		{
			bHit = false;
			RhythmComp.RhythmDanceArea.RhythmHitFailed(DanceActionName);

			UAnimSequence RandomFailAnim = RhythmComp.RandomHitFailAnimation;

			if(RandomFailAnim != nullptr)
			{
				FHazePlaySlotAnimationParams Params;
				Params.Animation = RandomFailAnim;

				Player.PlaySlotAnimation(Params);

				RhythmComp.DanceFailCooldown = RandomFailAnim.SequenceLength;
			}
			else
			{
				RhythmComp.DanceFailCooldown = 0.5f;
			}
		}
	}
}

