import Vino.SwingBar.SwingPhysicsSettings;
import Vino.ActivationPoint.ActivationPointStatics;

class USwingBarActivationPoint : UHazeActivationPoint
{
	default InitializeDistance(EHazeActivationPointDistanceType::Visible, 1300.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 850.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 500.f);	
	default ValidationIdentifier = EHazeActivationPointIdentifierType::Movement;

	TPerPlayer<bool> CooldownForPlayer;

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{	
		ASwingBarActor SwingBar = Cast<ASwingBarActor>(Owner);
		if (CooldownForPlayer[Player])
			return EHazeActivationPointStatusType::InvalidAndHidden;
		if (!SwingBar.IsSwingBarEnabled())
			return EHazeActivationPointStatusType::InvalidAndHidden;
		if (!Player.IsSelectedBy(SwingBar.AllowedPlayers))
			return EHazeActivationPointStatusType::InvalidAndHidden;
		if (SwingBar.IsSwingTooVertical())
			return EHazeActivationPointStatusType::InvalidAndHidden;
		if (SwingBar.IsSwingObstructed())
			return EHazeActivationPointStatusType::Invalid;
		return EHazeActivationPointStatusType::Valid;
	}

	UFUNCTION(BlueprintOverride)
	float SetupValidationScoreAlpha(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query, float CompareDistanceAlpha) const
	{	
		const float ScoreAlpha = ActivationPointsStatics::CalculateValidationScoreAlpha(Player, Query, CompareDistanceAlpha);
		return ScoreAlpha;
	}	
};

UCLASS(Abstract)
class ASwingBarActor : AHazeActor
{
    UPROPERTY(DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UArrowComponent SwingPosition;

    UPROPERTY(DefaultComponent, Attach = Root)
	USwingBarActivationPoint ActivationPoint;

    UPROPERTY(DefaultComponent, Attach = Root)
    UBoxComponent ObstructionArea;
    default ObstructionArea.SetCollisionProfileName(n"OverlapAll");

    UPROPERTY(Category = "Swing", EditDefaultsOnly, BlueprintReadOnly)
    EHazeSelectPlayer AllowedPlayers = EHazeSelectPlayer::Both;

    UPROPERTY(Category = "Physics", EditDefaultsOnly, BlueprintReadOnly)
    FSwingPhysicsSettings Physics;

    UPROPERTY(Category = "Swing", EditDefaultsOnly, BlueprintReadOnly)
    TSubclassOf<UHazeCapability> SwingCapability;

	private float AvoidObstructionChecksUntil = 0.f;
	private bool bWasObstructed = false;
	private bool bEnabled = true;

	bool IsSwingBarEnabled()
	{
		return bEnabled;
	}

    FTransform GetSwingTransform()
    {
        // Only apply the world-space yaw for our swing position.
        // We don't apply pitch or roll from our nail at all.
        FVector SwingLocation = SwingPosition.WorldLocation;
        FRotator SwingRotation = SwingPosition.WorldRotation;

        FVector NailOutward = SwingRotation.RotateVector(FVector::RightVector);
        FVector NailForward = NailOutward.CrossProduct(FVector::UpVector);

        FQuat SwingDir = FQuat::FindBetweenVectors(FVector::ForwardVector, NailForward);
        return FTransform(SwingDir, SwingLocation);
    }

    // Determine whether there is stuff in the way that prevents us from swinging on this nail
    bool IsSwingObstructed()
    {
		// Use cached value if we checked this recently
		float GameTime = Time::GetGameTimeSeconds();
		if (GameTime < AvoidObstructionChecksUntil)
			return bWasObstructed;

		// Don't recheck until later
		AvoidObstructionChecksUntil = GameTime + FMath::RandRange(0.5f, 1.f);

        TArray<AActor> IgnoreActors;
        IgnoreActors.Add(this);
        IgnoreActors.Add(Game::GetCody());
        IgnoreActors.Add(Game::GetMay());

        if (Root.AttachParent != nullptr)
            IgnoreActors.Add(Root.AttachParent.Owner);

        TArray<FHitResult> Hits;

        System::BoxTraceMultiByProfile(
            Start = ObstructionArea.WorldLocation,
            End = ObstructionArea.WorldLocation + FVector(0.f, 0.f, 0.01f),
            HalfSize = ObstructionArea.ScaledBoxExtent,
            Orientation = ObstructionArea.WorldRotation,
            ProfileName = n"PlayerCharacter",
            bTraceComplex = false,
            ActorsToIgnore = IgnoreActors,
            DrawDebugType = EDrawDebugTrace::None,
            OutHits = Hits,
            bIgnoreSelf = false
        );

        for (int i = 0, Count = Hits.Num(); i < Count; ++i)
        {
            UPrimitiveComponent HitComponent = Hits[i].Component;
            AActor Actor = Hits[i].Actor;
            bool bBlocking = Hits[i].bBlockingHit;

            ECollisionResponse Response = HitComponent.GetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter);
            
            // Only consider blocking hits
            if (Response != ECollisionResponse::ECR_Block)
                continue;

            // Ignore anything that's attached to one of our ignore actors
            AActor AttachedTo = Actor.GetAttachParentActor();
            bool bShouldIgnore = false;
            while (AttachedTo != nullptr)
            {
                if (IgnoreActors.Contains(AttachedTo))
                {
                    bShouldIgnore = true;
                    break;
                }
                AttachedTo = AttachedTo.GetAttachParentActor();
            }

            if (bShouldIgnore)
                continue;

            // We hit something with our trace, swing is obstructed
			bWasObstructed = true;
            return true;
        }

		bWasObstructed = false;
        return false;
    }

    // Determine whether the swing is at an angle that will not allow us to swing
    bool IsSwingTooVertical()
    {
        FVector SwingLocation = SwingPosition.WorldLocation;
        FRotator SwingRotation = SwingPosition.WorldRotation;

        FVector NailOutward = SwingRotation.RotateVector(FVector::RightVector);

        FVector NailFlatOutward = NailOutward;
        NailFlatOutward.Z = 0.f;
        NailFlatOutward = NailFlatOutward.GetSafeNormal();

        float VerticalAngle = 0.f;
        if (NailFlatOutward.IsNearlyZero())
        {
            // Flattened outward vector is zero, which means
            // we are perpendicular to the XY plane, in other words,
            // fully vertical!
            VerticalAngle = PI;
        }
        else
        {
            FQuat VerticalRotation = FQuat::FindBetweenVectors(NailFlatOutward, NailOutward);
            VerticalAngle = VerticalRotation.GetAngle();
        }

        return FMath::Abs(VerticalAngle) > Physics.MaxVerticalAngleToAllowSwing;
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Capability::AddPlayerCapabilityRequest(SwingCapability.Get());

        ObstructionArea.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlapObstructionArea");
        ObstructionArea.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlapObstructionArea");
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
    {
        Capability::RemovePlayerCapabilityRequest(SwingCapability.Get());
    }

	UFUNCTION()
	void EnableSwingBar()
	{
		bEnabled = true;
	}

	UFUNCTION()
	void DisableSwingBar()
	{
		bEnabled = false;
	}

    UFUNCTION()
    void OnBeginOverlapObstructionArea(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
    }

    UFUNCTION()
    void OnEndOverlapObstructionArea(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
    }
};