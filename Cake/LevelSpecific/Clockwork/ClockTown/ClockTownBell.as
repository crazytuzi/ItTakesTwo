import Vino.Interactions.InteractionComponent;
import Vino.Interactions.AnimNotify_Interaction;

class AClockTownBell : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BellBase;

	UPROPERTY(DefaultComponent, Attach = BellBase)
	USceneComponent BellRoot;

	UPROPERTY(DefaultComponent, Attach = BellRoot)
	UStaticMeshComponent BellMesh;

	UPROPERTY(DefaultComponent, Attach = BellRoot)
	USceneComponent RingerRoot;

	UPROPERTY(DefaultComponent, Attach = RingerRoot)
	UStaticMeshComponent RingerMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UInteractionComponent InteractionComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BellSlapAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayLeftAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyLeftAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayRightAnim;
	
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyRightAnim;

	bool bLeft = false;

	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.bHasLowerBound = false;
	default PhysValue.bHasUpperBound = false;
	default PhysValue.Friction = 2.9f;

	FHazeConstrainedPhysicsValue RingerPhysValue;
	default RingerPhysValue.LowerBound = -22.f;
	default RingerPhysValue.UpperBound = 22.f;
	default RingerPhysValue.LowerBounciness = 0.1f;
	default RingerPhysValue.UpperBounciness = 0.1f;
	default RingerPhysValue.Friction = 2.f;

	float BellLastRotation = 0.f;
	float RingerLastRotation = 0.f;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		BellBase.SetCullDistance(Editor::GetDefaultCullingDistance(BellBase) * CullDistanceMultiplier);
		BellMesh.SetCullDistance(Editor::GetDefaultCullingDistance(BellMesh) * CullDistanceMultiplier);
		RingerMesh.SetCullDistance(Editor::GetDefaultCullingDistance(RingerMesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"InteractionActivated");
	}

	UFUNCTION(NotBlueprintCallable)
	void InteractionActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		InteractionComp.Disable(n"Used");

		bLeft = !bLeft;
		
		UAnimSequence Anim;
		if (Player.IsMay())
			Anim = bLeft ? MayLeftAnim : MayRightAnim;
		else
			Anim = bLeft ? CodyLeftAnim : CodyRightAnim;

		FHazeAnimationDelegate AnimDelegate;
		AnimDelegate.BindUFunction(this, n"AnimFinished");
		Player.PlayEventAnimation(OnBlendingOut = AnimDelegate, Animation = Anim);

		FHazeAnimNotifyDelegate HitBellDelegate;
		HitBellDelegate.BindUFunction(this, n"HitBell");

		Player.BindOrExecuteOneShotAnimNotifyDelegate(Anim, UAnimNotify_Interaction::StaticClass(), HitBellDelegate);
		
		UHazeAkComponent::HazePostEventFireForget(BellSlapAudioEvent, GetActorTransform());
	}

	UFUNCTION(NotBlueprintCallable)
	void HitBell(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelComp, UAnimNotify Notify)
	{
		BellLastRotation = BellRoot.RelativeRotation.Roll;
		if (bLeft)
		{
			PhysValue.AddImpulse(800.f);
			RingerPhysValue.AddImpulse(-600.f);
		}
		else
		{
			PhysValue.AddImpulse(-800.f);
			RingerPhysValue.AddImpulse(600.f);
		}
		SetActorTickEnabled(true);
	}

	UFUNCTION(NotBlueprintCallable)
	void AnimFinished()
	{
		InteractionComp.Enable(n"Used");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PhysValue.SpringTowards(0.f, 20.f);
		PhysValue.Update(DeltaTime);

		BellRoot.SetRelativeRotation(FRotator(0.f, 0.f, PhysValue.Value));

		float BellRotationRate = BellRoot.RelativeRotation.Roll - BellLastRotation;

		RingerPhysValue.SpringTowards(0.f, 30.f);
		RingerPhysValue.AddAcceleration(BellRotationRate * 25.f);
		RingerPhysValue.Update(DeltaTime);

		if (RingerPhysValue.HasHitLowerBound())
			RingerHit(true);
		if (RingerPhysValue.HasHitUpperBound())
			RingerHit(false);

		RingerRoot.SetRelativeRotation(FRotator(0.f, 0.f, RingerPhysValue.Value));
		if (FMath::Abs(PhysValue.Velocity) < 0.1f && FMath::IsNearlyZero(PhysValue.Value, 0.1f))
			SetActorTickEnabled(false);
		else
			BellLastRotation = BellRoot.RelativeRotation.Roll;
	}

	void RingerHit(bool bHitLeft)
	{
		if (bHitLeft)
		{
			//PrintToScreen("Left", 2);
		}
		else
		{
			//PrintToScreen("Right", 2);
		}
	}
}