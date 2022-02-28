import Peanuts.Spline.SplineActor;

UCLASS(Abstract)
class AClassicStationaryAngelBaby : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase SkeletalMesh;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent CapsuleComponent;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeLazyPlayerOverlapComponent PlayerOverlap;
	default PlayerOverlap.RelativeLocation = FVector(60.0f, -50.0f, 130.0f);
	default PlayerOverlap.Shape.Type = EHazeShapeType::Sphere;
	default PlayerOverlap.Shape.SphereRadius = 380.0f;
	default PlayerOverlap.ResponsiveDistanceThreshold = 4000.0f;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 25000.f;

	UPROPERTY()
	UAnimSequence MH;
	UPROPERTY()
	UAnimSequence HitReaction;
	bool bPlayingImpactAnimation;

	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOverlap.OnPlayerBeginOverlap.AddUFunction(this, n"Handle_PlayerBeginOverlap");
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_PlayerBeginOverlap(AHazePlayerCharacter InPlayer)
	{
		PlayImpactAnimation();
	}

	UFUNCTION(NetFunction)
	void PlayImpactAnimation()
	{
		if(bPlayingImpactAnimation)
			return;

		bPlayingImpactAnimation = true;

		FHazePlaySlotAnimationParams AnimSettings = FHazePlaySlotAnimationParams();
		AnimSettings.Animation = HitReaction;
		AnimSettings.bLoop = false;
		AnimSettings.BlendTime = 0.2f;
		AnimSettings.StartTime = 0.f;
		AnimSettings.PlayRate = 1.f;
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
	
		OnBlendingOut.BindUFunction(this, n"AnimFinished");
		SkeletalMesh.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, AnimSettings);
		//System::SetTimer(this, n"AnimFinished", AnimSettings.GetPlayLength(), false);
	}

	UFUNCTION()
	void AnimFinished()
	{
		FHazePlaySlotAnimationParams AnimSettings = FHazePlaySlotAnimationParams();
		AnimSettings.Animation = MH;
		AnimSettings.bLoop = true;
		AnimSettings.BlendTime = 0.2f;
		AnimSettings.StartTime = 0.f;
		AnimSettings.PlayRate = 1.f;
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		SkeletalMesh.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, AnimSettings);

		System::SetTimer(this, n"ReAllowImpactAnimation", 1.f, false);
	}
	UFUNCTION()
	void ReAllowImpactAnimation()
	{
		bPlayingImpactAnimation = false;
	}
}
