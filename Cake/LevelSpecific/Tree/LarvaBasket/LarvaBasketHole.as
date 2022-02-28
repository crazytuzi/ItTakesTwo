import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketSettings;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketBall;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketManager;

class ALarvaBasketHole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

    UPROPERTY(DefaultComponent)
    UHazeSkeletalMeshComponentBase SkelMesh;
	default SkelMesh.AnimationMode = EAnimationMode::AnimationSingleNode;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = Head)
	USceneComponent GrabBallRoot;

	UPROPERTY(DefaultComponent)
	UBoxComponent ScoreCollision;

    UPROPERTY(Category = "Animation")
    UAnimSequence AnimMH;

    UPROPERTY(Category = "Animation")
    UAnimSequence AnimGrab;

    bool bIsActive = false;
    bool bIsFacingAway = false;
	ALarvaBasketBall GrabbedBall = nullptr;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SkelMesh.AnimationData.AnimToPlay = AnimMH;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ScoreCollision.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		ScoreCollision.OnComponentEndOverlap.AddUFunction(this, n"HandleEndOverlap");
	}

    UFUNCTION()
    void HandleBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
    	auto Ball = Cast<ALarvaBasketBall>(OtherActor);
    	if (Ball == nullptr)
    		return;

        if (Ball.bIsHeld)
            return;

        if (Ball.bHaveBounced)
            return;

    	if (GrabbedBall != nullptr)
    		return;

    	if (!Ball.PlayerOwner.HasControl())
    		return;

    	NetBallScore(Ball, ELarvaBasketScoreType::Low);
    }

    UFUNCTION()
    void HandleEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
    }

    UFUNCTION(NetFunction)
    void NetBallScore(ALarvaBasketBall Ball, ELarvaBasketScoreType InScoreType)
    {
    	if (GrabbedBall != nullptr)
            GrabbedBall.DeactivateBall();

    	LarvaBasketPlayerGainScore(Ball.PlayerOwner, LarvaBasketGetScoreForType(InScoreType));
    	Ball.AttachToComponent(GrabBallRoot, NAME_None, EAttachmentRule::SnapToTarget);
    	Ball.bIsHeld = true;
    	GrabbedBall = Ball;

    	OnScored();

		FHazePlaySlotAnimationParams Params;
		Params.Animation = AnimGrab;
		Params.bLoop = false;

		SkelMesh.PlaySlotAnimation(
            OnBlendedIn = FHazeAnimationDelegate(),
            OnBlendingOut = FHazeAnimationDelegate(this, n"HandleGrabBlendedOut"),
            PlaySlotAnimParams = Params
        );

        // Spawn little +1 thingy
        auto Minigame = LarvaBasketManager.Minigame;
        FMinigameWorldWidgetSettings MinigameWorldSettings;
        
        MinigameWorldSettings.MinigameTextMovementType = EMinigameTextMovementType::AccelerateToHeight;
        MinigameWorldSettings.TextJuice = EInGameTextJuice::BigChange; //Animation 'juice' that will be added later
        
        MinigameWorldSettings.MoveSpeed = 30.f; // Starting move speed
        MinigameWorldSettings.TimeDuration = 0.75f; // How long it should last for before it fades out or completely disappears
        MinigameWorldSettings.FadeDuration = 0.6f; // Opacity fade time
        MinigameWorldSettings.TargetHeight = 140.f; // If movement type is 'ToHeight', the height it will reach before stopping

        MinigameWorldSettings.MinigameTextColor = Ball.PlayerOwner.IsMay() ? EMinigameTextColor::May : EMinigameTextColor::Cody;  

        Minigame.CreateMinigameWorldWidgetNumber(EMinigameTextPlayerTarget::Cody, 1, ActorLocation, MinigameWorldSettings);
        Minigame.CreateMinigameWorldWidgetNumber(EMinigameTextPlayerTarget::May, 1, ActorLocation, MinigameWorldSettings);

        LarvaBasketPlayHitBark(Ball.PlayerOwner);
    }

    UFUNCTION()
    void HandleGrabBlendedOut()
    {
        if (GrabbedBall != nullptr)
        {
            GrabbedBall.DeactivateBall();
            GrabbedBall = nullptr;
        }

        FHazePlaySlotAnimationParams Params;
        Params.Animation = AnimMH;
        Params.bLoop = true;
        SkelMesh.PlaySlotAnimation(Params = Params);
    }

    void ActivateHole()
    {
		FHazePlaySlotAnimationParams Params;
		Params.Animation = AnimMH;
		Params.bLoop = true;
		SkelMesh.PlaySlotAnimation(Params = Params);

        EnableActor(this);
        bIsActive = true;
    }

    void DeactivateHole()
    {
        if (GrabbedBall != nullptr)
        {
            GrabbedBall.DeactivateBall();
            GrabbedBall = nullptr;
        }

        DisableActor(this);
        bIsActive = false;
    }

	void SetScoreType()
	{
	}

	UFUNCTION(BlueprintEvent)
	void OnScoreTypeSet(ELarvaBasketScoreType Type) {}

	UFUNCTION(BlueprintEvent)
	void OnScored() {}
}