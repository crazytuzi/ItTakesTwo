import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourCapability;

class UBeetleBehaviourStunnedCapability : UBeetleBehaviourCapability
{
	default State = EBeetleState::Stunned;

	float EndDuration = 0.f;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		
		// We no longer switch target here as that may cause network issues.

		// No need to block anims any more
		AnimComp.UnblockNewAnims();

		EndDuration = AnimFeature.Stunned_End.SequenceLength;
		if (Owner.IsPlayingAnimAsSlotAnimation(AnimFeature.Stunned_Start) || Owner.IsPlayingAnimAsSlotAnimation(AnimFeature.Stunned_MH))
		{
			float MhDuration = FMath::Max(0.001f, BehaviourComp.StunTime - EndDuration - Time::GetGameTimeSeconds());
			System::SetTimer(this, n"ExitStun", MhDuration, false);
		}
		else
		{
			AnimComp.PlayAnim(AnimFeature.Stunned_Start, this, n"OnStartAnimComplete");
		}
    }

	UFUNCTION()
	void OnStartAnimComplete()
	{
		if (!IsActive())
			return;
		
		if (Time::GetGameTimeSeconds() >  BehaviourComp.StunTime - EndDuration)
		{
			// Exit immediately
			ExitStun();
		}
		else
		{
			// Play mh for a while
			float MhDuration = FMath::Max(0.f, BehaviourComp.StunTime - EndDuration - Time::GetGameTimeSeconds());
			AnimComp.PlayAnim(AnimFeature.Stunned_MH, bLoop = true);
			System::SetTimer(this, n"ExitStun", MhDuration, false);
		}
	}

	UFUNCTION()
	void ExitStun()
	{
		if (!IsActive())
			return;
		AnimComp.PlayAnim(AnimFeature.Stunned_End, this, n"OnEndAnimComplete");
	}

	UFUNCTION()
	void OnEndAnimComplete()
	{
		if (!IsActive())
			return;
		BehaviourComp.State = EBeetleState::Pursue;
	}
}