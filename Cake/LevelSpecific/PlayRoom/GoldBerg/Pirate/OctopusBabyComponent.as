class UOctopusBabyComponent : UActorComponent
{  
	ESquidState NextState =  ESquidState::MH;
	ESquidState CurrentState = ESquidState::Alerted;
	ESquidState PreviousState = ESquidState::Alerted;

	UPROPERTY()
	FHazePlaySequenceData MH;
	
	UPROPERTY()
	FHazePlaySequenceData Alerted;

	UPROPERTY()
	FHazePlaySequenceData AlertedMH;
	
	UPROPERTY()
	FHazePlaySequenceData Attack;

	UPROPERTY()
	FHazePlaySequenceData Float;

	UPROPERTY()
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	FHazePlaySlotAnimationParams ActiveSlotAnim;

	FHazeAnimationDelegate OnBlendingOut;
	float UpdateAnimationTimer = 0.0f;
	float UpdateAnimationCooldown = 0.15f;

	bool bUpdatedAttackAnimation = false;

	UFUNCTION()
	void UpdateAnimation(float DeltaTime)
	{
		UpdateAnimationTimer += DeltaTime;

		if(UpdateAnimationTimer < UpdateAnimationCooldown)
			return;

		UpdateAnimationTimer = 0.0f;

		if((CurrentState == ESquidState::Attack && bUpdatedAttackAnimation) || CurrentState != NextState)
		{
			switch(NextState)
			{
				case ESquidState::MH:
				{
					PlayAnimation(MH, true, MH.PlayRate);
					break;
				}
				case ESquidState::Alerted:
				{
					PlayAnimation(Alerted, false, Alerted.PlayRate);		
					break;
				}
				case ESquidState::Alerted_MH:
				{
					PlayAnimation(AlertedMH, true, AlertedMH.PlayRate);
					break;
				}
				case ESquidState::Attack:
				{
					PlayAnimation(Attack, false, Attack.PlayRate);
					break;
				}
				case ESquidState::Float:
				{
					PlayAnimation(Float, true, Float.PlayRate);
					break;
				}
			}

			if(bUpdatedAttackAnimation)
				bUpdatedAttackAnimation = false;

			if(CurrentState != ESquidState::Attack)
				PreviousState = CurrentState;
			CurrentState = NextState;
		}
	}

	UFUNCTION()
	void ReturnToPreviousAnim()
	{
		SetNextOctopusBabyAnimation(PreviousState);
	}


	UFUNCTION()
	void SetNextOctopusBabyAnimation(ESquidState NextAnimationState)
	{
		NextState = NextAnimationState;
		if(OnBlendingOut.IsBound())
		{
			OnBlendingOut.Clear();
			if(NextState == ESquidState::Attack)
				bUpdatedAttackAnimation = true;
		}
	}

	UFUNCTION()
	void PlayAnimation(const FHazePlaySequenceData& Anim, bool bLooping = false, float CustomPlayRate = -1.f)
	{
		if(Anim.Sequence != nullptr)
		{
			FHazeAnimationDelegate OnBlendingIn;
			//FHazeAnimationDelegate OnBlendingOut;
			
			if(!bLooping)
				OnBlendingOut.BindUFunction(this, n"AnimationFinished");
			
			FHazePlaySlotAnimationParams SlotAnimParams;
			SlotAnimParams.Animation = Anim.Sequence;
			SlotAnimParams.PlayRate = Anim.PlayRate;
			if(CustomPlayRate > 0)
			{
				SlotAnimParams.PlayRate = CustomPlayRate;
			}
			SlotAnimParams.bLoop = bLooping;

			SkeletalMesh.PlaySlotAnimation(
				OnBlendingIn, 
				OnBlendingOut,
				SlotAnimParams
				);

			ActiveSlotAnim = SlotAnimParams;
		}
	}

	UFUNCTION()
	void AnimationFinished()
	{
		OnBlendingOut.Clear();
		if(CurrentState == ESquidState::Alerted)
		{
			SetNextOctopusBabyAnimation(ESquidState::Alerted_MH);
		}
		else if(CurrentState == ESquidState::Attack)
		{
			//SetNextOctopusBabyAnimation(ESquidState::Alerted_MH);
			ReturnToPreviousAnim();
		}
		
	}
}


enum ESquidState
{
    MH,
	Alerted,
	Alerted_MH,
	Attack,
	Float
}

