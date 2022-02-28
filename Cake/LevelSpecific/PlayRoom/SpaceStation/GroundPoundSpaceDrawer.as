import Vino.Buttons.GroundPoundButton;
import Vino.Movement.Components.GroundPound.GroundPoundGuideComponent;

class AGroundPoundSpaceDrawer : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent RootComp;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    USceneComponent DrawerRoot;

    UPROPERTY(DefaultComponent, Attach = DrawerRoot)
    UStaticMeshComponent DrawerMesh;
	default DrawerMesh.RemoveTag(ComponentTags::WallSlideable);

	UPROPERTY(DefaultComponent, Attach = DrawerRoot)
	UStaticMeshComponent TelescopeMesh;
	default TelescopeMesh.RelativeLocation = FVector(400.f, 0.f, 0.f);

    UPROPERTY()
    AGroundPoundButton Button;
    AGroundPoundButton LastKnownButton;

    UPROPERTY()
    FHazeTimeLike MoveDrawerTimeLike;
    default MoveDrawerTimeLike.Duration = 0.25f;

    UPROPERTY()
    bool bPreviewTargetLocation = false;

    UPROPERTY(meta = (MakeEditWidget))
    FVector TargetLocation = FVector(250.f, 0.f, 0.f);

    UPROPERTY(BlueprintReadOnly)
    UAkAudioEvent SpaceDrawerResetEvent;

    UPROPERTY(BlueprintReadOnly)
    UAkAudioEvent SpaceDrawerPushEvent;

    bool bReturning = false;

    UFUNCTION(BlueprintEvent)
    void BP_SpaceDrawerPush()
    {}

    UFUNCTION(BlueprintEvent)
    void BP_SpaceDrawerReset()
    {}

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        if (bPreviewTargetLocation)
        {
            DrawerRoot.SetRelativeLocation(TargetLocation);
        }
        else
        {
            DrawerRoot.SetRelativeLocation(FVector::ZeroVector);
        }

        if (Button != nullptr)
        {
            LastKnownButton = Button;
            Button.AttachToComponent(DrawerRoot, AttachmentRule = EAttachmentRule::KeepWorld);
            Button.SetActorRelativeLocation(FVector(-195.f, 0.f, 200.f), false, FHitResult(), true);
            Button.SetActorRelativeRotation(FRotator(90.f, 0.f, 0.f), false, FHitResult(), true);

			UGroundPoundGuideComponent GroundPoundGuideComp = UGroundPoundGuideComponent::Get(Button);
			if (GroundPoundGuideComp != nullptr)
			{
				GroundPoundGuideComp.ActivationRadius = 200.f;
				GroundPoundGuideComp.TargetRadius = 130.f;
				GroundPoundGuideComp.MinHeightAboveActor = 75.f;
			}

			UHazeNetworkControlSideInitializeComponent NetComp = UHazeNetworkControlSideInitializeComponent::Create(Button);
			NetComp.ControlSide = EHazePlayer::May;
        }
        else if (LastKnownButton != nullptr)
        {
            LastKnownButton.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
            LastKnownButton = nullptr;
        }
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if (Button != nullptr)
            Button.OnButtonGroundPoundStarted.AddUFunction(this, n"ButtonPounded");

        MoveDrawerTimeLike.BindUpdate(this, n"UpdateMoveDrawer");
        MoveDrawerTimeLike.BindFinished(this, n"FinishMoveDrawer");
    }

    UFUNCTION()
    void ButtonPounded(AHazePlayerCharacter Player)
    {
		MoveDrawerTimeLike.PlayFromStart();
		UHazeAkComponent::HazePostEventFireForget(SpaceDrawerPushEvent, this.GetActorTransform());
        BP_SpaceDrawerPush();
    }

    UFUNCTION()
    void UpdateMoveDrawer(float CurValue)
    {
        FVector CurLoc = FMath::Lerp(FVector::ZeroVector, TargetLocation, CurValue);
        DrawerRoot.SetRelativeLocation(CurLoc);

		FVector CurTelescopeLoc = FMath::Lerp(FVector(400.f, 0.f, 0.f), FVector(530.f, 0.f, 0.f), CurValue);
		TelescopeMesh.SetRelativeLocation(CurTelescopeLoc);
    }

    UFUNCTION()
    void FinishMoveDrawer()
    {
        if (bReturning)
        {
            MoveDrawerTimeLike.SetPlayRate(1.f);
            bReturning = false;
            Button.ResetButton();
        }
        else
        {
            MoveDrawerTimeLike.SetPlayRate(0.1f);
            bReturning = true;

            System::SetTimer(this, n"ReverseDrawerMovement", 4.f, false);
        }
    }

    UFUNCTION()
    void ReverseDrawerMovement()
    {
		if (Game::GetCody().HasControl())
			NetReverseDrawerMovement();
    }

	UFUNCTION(NetFunction)
	void NetReverseDrawerMovement()
	{
		MoveDrawerTimeLike.ReverseFromEnd();
		UHazeAkComponent::HazePostEventFireForget(SpaceDrawerResetEvent, this.GetActorTransform());
        BP_SpaceDrawerReset();
	}
}