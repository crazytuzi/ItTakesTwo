import Cake.LevelSpecific.Tree.Beetle.Animation.BeetleAnimFeature;

enum EBeetleAnimationState
{
	Gore,
	Stomp,
	PounceStart,
	PounceLand,
	MultiSlam,
	Shake,
	Stun,
	TelegraphCharge,
	TelegraphPounce,
	TelegraphMultiSlam,
	Turning,
}

event void FBeetleAnimEvent();

class UBeetleAnimationComponent : UActorComponent
{
	AHazeCharacter CharOwner;
	UAnimSequence PendingMH;
	bool bBlocked = false;
	UBeetleAnimFeature AnimFeature;

	FBeetleAnimEvent OnShockwaveNotify;
	FBeetleAnimEvent OnDealCollisionDamageBegin;
	FBeetleAnimEvent OnDealCollisionDamageEnd;
	FBeetleAnimEvent OnLaunchNotify;
	UPROPERTY()
	EBeetleAnimationState AnimState;
	UPROPERTY()
	float TurnValue = 0.f;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CharOwner = Cast<AHazeCharacter>(Owner);
		AnimFeature = Cast<UBeetleAnimFeature>(CharOwner.Mesh.GetFeatureByClass(UBeetleAnimFeature::StaticClass()));
	}

	void BlockNewAnims()
	{
		bBlocked = true;
	}
	void UnblockNewAnims()
	{
		bBlocked = false;
	}

	void PlayAnim(UAnimSequence Anim, UObject DoneDelegateObject = nullptr, FName DoneDelegateName = NAME_None, bool bLoop = false, float BlendTime = 0.2f)
	{
		if (bBlocked)
		{
			// Don't allow any anims to play right now, count them as done next tick
			if (DoneDelegateObject != nullptr)
				System::SetTimer(DoneDelegateObject, DoneDelegateName, 0.001f, false);
			return;
		}

		FHazeAnimationDelegate AnimDone;
		if (DoneDelegateObject != nullptr)
			AnimDone.BindUFunction(DoneDelegateObject, DoneDelegateName);
		PendingMH = nullptr;
		CharOwner.PlaySlotAnimation(Animation = Anim, OnBlendingOut = AnimDone, bLoop = bLoop, BlendTime = BlendTime);
	}		

	void PlayBlendSpace(UBlendSpaceBase BlendSpace, float BlendTime = 0.2f, float PlayRate = 1.f)
	{
		if (bBlocked)
			return;

		CharOwner.StopAllSlotAnimations(BlendTime);
		CharOwner.PlayBlendSpace(BlendSpace, BlendTime, PlayRate = PlayRate);
		PendingMH = nullptr;
	}

	void PlayStartMH(UAnimSequence StartAnim, UAnimSequence MHAnim, float BlendTime = 0.2f)
	{
		if (bBlocked)
			return;

		PendingMH = MHAnim;
		FHazeAnimationDelegate StartAnimDone;
		StartAnimDone.BindUFunction(this, n"OnStartAnimDone");
		CharOwner.PlaySlotAnimation(Animation = StartAnim, OnBlendingOut = StartAnimDone);
	}

	void PlayAdditiveHurt(const FVector& DamageDirection)
	{
		FHazePlayAdditiveAnimationParams Params;
		Params.BoneFilter = EHazeBoneFilterTemplate::BoneFilter_Neck;
		Params.Animation = AnimFeature.AdditiveHurt_Front;
		Params.BlendTime = 0.05f;
		FVector DamageDir = DamageDirection.GetSafeNormal2D();
		if (DamageDir.DotProduct(Owner.ActorForwardVector) > -0.7f)
		{
			if (DamageDir.DotProduct(Owner.ActorRightVector) > 0.f)
				Params.Animation = AnimFeature.AdditiveHurt_Left;
			else
				Params.Animation = AnimFeature.AdditiveHurt_Right;
		}
		CharOwner.PlayAdditiveAnimation(FHazeAnimationDelegate(), Params);
	}

	UFUNCTION()
	void OnStartAnimDone()
	{
		// Alllow this even if locked
		if (PendingMH != nullptr)	
			CharOwner.PlaySlotAnimation(Animation = PendingMH, BlendTime = 0.f, bLoop = true);
	}

	void ShockwaveNotify()
	{
		OnShockwaveNotify.Broadcast();
	}

	void DealCollisionDamageBegin()
	{
		OnDealCollisionDamageBegin.Broadcast();
	}

	void DealCollisionDamageEnd()
	{
		OnDealCollisionDamageEnd.Broadcast();
	}

	void LaunchNotify()
	{
		OnLaunchNotify.Broadcast();
	}
}