import Peanuts.Spline.SplineActor;

UCLASS(Abstract)
class AClassicPetAngelBabies : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase SkeletalMesh;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent CapsuleComponent;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent CapsuleComponentHead;
	UPROPERTY()
	UAnimSequence IdleMH;
	UPROPERTY()
	UAnimSequence Enter;
	UPROPERTY()
	UAnimSequence Exit;
	UPROPERTY()
	UAnimSequence MH;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 25000.f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime){}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CapsuleComponent.AttachToComponent(SkeletalMesh, SkeletalMesh.GetSocketBoneName(n"Spine"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		CapsuleComponent.AddLocalOffset(FVector(-60.5f, 7.2f, 11.5f));
		CapsuleComponentHead.AttachToComponent(SkeletalMesh, SkeletalMesh.GetSocketBoneName(n"Head"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
	}

	UFUNCTION()
	void StartEnterAnimation()
	{
		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"StartMHAnimation");
		PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = Enter, bLoop = false);

	}
	UFUNCTION()
	void StartMHAnimation()
	{
		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;
		PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = MH, bLoop = true);
	}


	UFUNCTION()
	void StartExitAnimation()
	{
		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"StartIdleMH");
		PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = Exit, bLoop = false);
	}
	UFUNCTION()
	void StartIdleMH()
	{
		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;
		PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = IdleMH, bLoop = true);
	}
}
