import Peanuts.Triggers.PlayerTrigger;
import Vino.Jumppad.LaunchCharactercapability;
import Vino.Movement.Components.MovementComponent;

event void FOnPlayerLaunched(AHazePlayerCharacter Player);
event void FOnPlayerDoubleBounced();

enum EJumppadMode
{
    LaunchStraightUp,
    LandOnTransform,
    LaunchAndGetPushedFromCenter,
    LandOnTransformBasedOnDirection
};

//UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD")
class AJumppad : APlayerTrigger
{
    UPROPERTY(Category = "Events")
	FOnPlayerLaunched OnLaunched;

    UPROPERTY(Category = "Events")
    FOnPlayerLaunched OnStartLaunch;

    UPROPERTY(Category = "Events")
    FOnPlayerDoubleBounced OnDoubleBounced;

    UPROPERTY(Meta = (MakeEditWidget))
    FTransform Transform;

    UPROPERTY(Meta = (MakeEditWidget))
    FTransform DoubleJumpTransform;

    UPROPERTY()
    bool StartActive = true;

    UPROPERTY()
    bool SupportDoubleBounce = false;

    UPROPERTY(meta = (InlineEditConditionToggle))
    bool ShouldOverrideAircontrol = false;

    UPROPERTY(meta = (EditCondition = "ShouldOverrideAircontrol"))
    float OverrideAircontrol = 2600.0f;

    float AllowedTimeBetweenDoubleJump = 1;

    UPROPERTY()
    EJumppadMode JumpMode;

    UPROPERTY()
    float LaunchArc = 0.5f;

    UPROPERTY()
    float LaunchRadius = 500.f;


    AHazePlayerCharacter LaunchedPlayer;

    bool CodyOverlapping = false;
    bool MayOverlapping = false;

    bool AllowLaunchCody = true;
    bool AllowLaunchMay = true;

    bool HasRecentlyDoubleBounced = false;
    float RecentlyDoubleBouncedTimer = 0;
    float MaxRecentDoubleBounceTimer = 0.4f;

    float BounceTimer;
    float MaxBounceTime = 0.3f;

    bool IsActive;

    FVector GetGoalLocation(FVector CharacterLocation, FVector CharacterVelocity, bool ForceDoubleJump)
    {
        FVector Direction = FVector::ZeroVector;

        switch (JumpMode)
        {
            case EJumppadMode::LandOnTransform:

            if (ForceDoubleJump)
            {
                return ActorTransform.TransformPosition(DoubleJumpTransform.Location);
            }

            else
            {
                return ActorTransform.TransformPosition(Transform.Location);
            }

            case EJumppadMode::LaunchAndGetPushedFromCenter:
                Direction = (CharacterLocation - ActorLocation) * 1.2f;
                Direction.Z = Transform.Location.Z;

                return Direction + ActorLocation;

            case EJumppadMode::LaunchStraightUp:
                if (ForceDoubleJump)
                {
                    // Adding a slight offset to not make the arc-logic in the LaunchCharacter capability to completely break.
                    Direction = CharacterLocation + (ActorTransform.TransformPosition(DoubleJumpTransform.Location) - ActorLocation) + FVector(0.1f,0.1f,0.1f);
                }

                else
                {
                    // Adding a slight offset to not make the arc-logic in the LaunchCharacter capability to completely break.
                    Direction = CharacterLocation + (ActorTransform.TransformPosition(Transform.Location) - ActorLocation) + FVector(0.1f,0.1f,0.1f);
                }

                return Direction;

            case EJumppadMode::LandOnTransformBasedOnDirection:
                Direction = CharacterVelocity;
                Direction.Normalize();
                Direction.Z = 0.f;

                Direction = CharacterLocation + (Direction * LaunchRadius);

                Direction.Z = ActorTransform.Location.Z + Transform.Location.Z;

                return Direction;
        }

        return ActorTransform.TransformPosition(Transform.Location);
    }

	UFUNCTION(BlueprintPure)
    bool GetIsDoubleJumping()
    {
        return (MayOverlapping && CodyOverlapping);
    }
    

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		Super::BeginPlay();

        Capability::AddPlayerCapabilityRequest(ULaunchCharactercapability::StaticClass());
        IsActive = StartActive;
        SetActorTickEnabled(SupportDoubleBounce);
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
    {
        Capability::RemovePlayerCapabilityRequest(ULaunchCharactercapability::StaticClass());
    }

    UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
        System::FlushPersistentDebugLines();
        //Shape::CreateTriggerShape(this, this, Shape, Transform);
		Transform.Scale3D = FVector(1 / GetActorScale3D().X,1 / GetActorScale3D().Y,1 / GetActorScale3D().Z);
        DoubleJumpTransform.Scale3D = FVector(1 / GetActorScale3D().X,1 / GetActorScale3D().Y,1 / GetActorScale3D().Z);
        
        // As the location of the transform has to be straight up for launchstraightup to work I hard-set the location to be 0 in X and Y.
        if (JumpMode == EJumppadMode::LaunchStraightUp || JumpMode == EJumppadMode::LaunchAndGetPushedFromCenter)
        {
            FVector Transformlocation = Transform.Location;

            Transformlocation.X = 0;
            Transformlocation.Y = 0;

            Transform.SetLocation(Transformlocation);

            FVector DoubleJumpTransformLocation = DoubleJumpTransform.Location;
            DoubleJumpTransformLocation.X = 0;
            DoubleJumpTransformLocation.Y = 0;

            DoubleJumpTransform.SetLocation(DoubleJumpTransformLocation);
        }
        else if(JumpMode == EJumppadMode::LandOnTransformBasedOnDirection)
        {
            FVector Transformlocation = Transform.Location;

            Transformlocation.X = 0;
            Transformlocation.Y = 0;

            Transform.SetLocation(Transformlocation);

            System::DrawDebugCircle(FVector(ActorLocation.X, ActorLocation.Y, ActorTransform.TransformPosition(Transformlocation).Z), LaunchRadius, 60, FLinearColor::Green, 5000.f, 10.f, FVector::RightVector, FVector::ForwardVector, true);
        }
	}

    void LeaveTrigger(AActor Actor) override
    {
        AHazeCharacter Character = Cast<AHazeCharacter>(Actor);

        if (Cast<AHazePlayerCharacter>(Actor).IsCody())
        {
            CodyOverlapping = false;
            AllowLaunchCody = true;
        }
        else
        {
            MayOverlapping = false;
            AllowLaunchMay = true;
        }
    }

    void EnterTrigger(AActor Actor) override
    {
        AHazeCharacter Character = Cast<AHazeCharacter>(Actor);

        if (!IsActive)
        {
            return;
        }

        else
        {
            if (SupportDoubleBounce)
            {
                if (Cast<AHazePlayerCharacter>(Actor).IsCody())
                {
                    CodyOverlapping = true;
                }

                else
                {
                    MayOverlapping = true;
                }
                
                OnStartLaunch.Broadcast(Cast<AHazePlayerCharacter>(Character));
            }
            
            else
            {
                LaunchedPlayer = Cast<AHazePlayerCharacter>(Character);

                if (LaunchedPlayer.HasControl())
                {
                    NetLaunchPlayer(Character, false);
                }
            }
        }
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float Delta)
	{
        if (CodyOverlapping || MayOverlapping)
        {
            BounceTimer += Delta;
        }

        if (SupportDoubleBounce)
        {
            if (HasRecentlyDoubleBounced)
            {
                RecentlyDoubleBouncedTimer += Delta;
                if (RecentlyDoubleBouncedTimer > MaxRecentDoubleBounceTimer)
                {
                    HasRecentlyDoubleBounced = false;
                    RecentlyDoubleBouncedTimer = 0;
                }
            }

            if (CodyOverlapping && SupportDoubleBounce && BounceTimer > MaxBounceTime || 
                MayOverlapping && SupportDoubleBounce && BounceTimer > MaxBounceTime)
            {
                if(CodyOverlapping && MayOverlapping && !HasRecentlyDoubleBounced)
                {
                    DoubleBounceLaunchPlayers();
                }
                //else if (CodyOverlapping && Game::GetCody().HasControl() && AllowLaunchCody)
                else if (CodyOverlapping && Game::GetCody().HasControl())
                {
                    NetLaunchPlayer(Game::GetCody(), false);
                }

                //else if (MayOverlapping && Game::GetMay().HasControl() && AllowLaunchMay)
                else if (MayOverlapping && Game::GetMay().HasControl())
                {
                    NetLaunchPlayer(Game::GetMay(), false);
                }
            }
        }
	}

    UFUNCTION(NetFunction)
    void DoubleBounceLaunchPlayers()
    {
        if (!HasRecentlyDoubleBounced)
        {
            NetSetHasRecentlyDoubleBounced();
            NetLaunchPlayer(Game::GetCody(), true);
            NetLaunchPlayer(Game::GetMay(), true);
        }
    }

    UFUNCTION(NetFunction)
    void NetSetHasRecentlyDoubleBounced()
    {
        HasRecentlyDoubleBounced = true;
        BounceTimer = 0;
        OnDoubleBounced.Broadcast();
    }

	UFUNCTION(NetFunction)
    void NetLaunchPlayer(AHazeCharacter Player, bool ForceDoubleJump)
    {
        BounceTimer = 0;

        if (Cast<AHazePlayerCharacter>(Player).IsCody())
        {
            AllowLaunchCody = false;
        }
        else
        {
            AllowLaunchMay = false;
        }

        Player.SetCapabilityAttributeValue(n"LaunchArc",LaunchArc);
        Player.SetCapabilityAttributeVector(n"LaunchGoalLocation", GetGoalLocation(Player.ActorLocation, Player.GetActualVelocity(), ForceDoubleJump));

        if (ShouldOverrideAircontrol)
        {
            Player.SetCapabilityAttributeValue(n"LaunchAirControl", OverrideAircontrol);
        }

        OnLaunched.Broadcast(Cast<AHazePlayerCharacter>(Player));
    }

    UFUNCTION()
    void Setactive(bool Active)
    {
        IsActive = Active;
    }
}