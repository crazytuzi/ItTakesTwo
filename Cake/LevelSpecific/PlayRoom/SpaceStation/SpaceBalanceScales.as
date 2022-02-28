import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Movement.Components.MovementComponent;

UCLASS(Abstract)
class ASpaceBalanceScales : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent ScaleBase;

    UPROPERTY(DefaultComponent, Attach = ScaleBase)
    UStaticMeshComponent ScaleBaseMesh;

    UPROPERTY(DefaultComponent, Attach = ScaleBase)
    USceneComponent ScaleArmBase;

    UPROPERTY(DefaultComponent, Attach = ScaleArmBase)
    UStaticMeshComponent ScaleArmMesh1;
    default ScaleArmMesh1.RelativeLocation = FVector(400.f, 0.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = ScaleArmBase)
    UStaticMeshComponent ScaleArmMesh2;
    default ScaleArmMesh2.RelativeLocation = FVector(-400.f, 0.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = ScaleArmBase)
    UStaticMeshComponent ScalePlatformLeft;
    default ScalePlatformLeft.RelativeLocation = FVector(0.f, -1500.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = ScaleArmBase)
    UStaticMeshComponent ScalePlatformRight;
    default ScalePlatformRight.RelativeLocation = FVector(0.f, 1500.f, 0.f);

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 6000.f;

    TArray<AHazePlayerCharacter> PlayersOnLeftPlatform;
    TArray<AHazePlayerCharacter> PlayersOnRightPlatform;

    float PitchPerPlayer = 8.f;

    UPROPERTY()
    bool bPreviewMaximumPitch = false;
    UPROPERTY()
    bool bPreviewLeft = false;

	UPROPERTY(NotEditable)
	float CurrentRotationSpeed = 0.f;

    FCharacterSizeValues CharacterSizeWeightMultiplierValues;
    default CharacterSizeWeightMultiplierValues.Small = 0.1f;
    default CharacterSizeWeightMultiplierValues.Medium = 1.f;
    default CharacterSizeWeightMultiplierValues.Large = 6.f;

	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.Friction = 2.5f;
	default PhysValue.LowerBound = -52.f;
	default PhysValue.UpperBound = 52.f;
	default PhysValue.bHasLowerBound = true;
	default PhysValue.bHasUpperBound = true;

	float PreviousPitch = 0.f;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {   
		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlatform");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
    }

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
	{
		if (Hit.Component == ScalePlatformLeft)
			PlayersOnLeftPlatform.Add(Player);
		else if (Hit.Component == ScalePlatformRight)
			PlayersOnRightPlatform.Add(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void LeavePlatform(AHazePlayerCharacter Player)
	{
		if (PlayersOnLeftPlatform.Contains(Player))
			PlayersOnLeftPlatform.Remove(Player);
		if (PlayersOnRightPlatform.Contains(Player))
			PlayersOnRightPlatform.Remove(Player);
	}

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {   
        float PitchToPreview = (CharacterSizeWeightMultiplierValues.Large - 1) * PitchPerPlayer;
        if (bPreviewLeft)
            PitchToPreview *= -1;

        if (bPreviewMaximumPitch)
            ScaleArmBase.SetRelativeRotation(FRotator(0.f, 0.f, PitchToPreview));
        else
            ScaleArmBase.SetRelativeRotation(FRotator::ZeroRotator);

        ScalePlatformLeft.SetWorldRotation(FRotator(0.f, ScalePlatformLeft.WorldRotation.Yaw, 0.f));
        ScalePlatformRight.SetWorldRotation(FRotator(0.f, ScalePlatformRight.WorldRotation.Yaw, 0.f));
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
        float DesiredLeftPitch = 0.f;
        for (AHazePlayerCharacter Player : PlayersOnLeftPlatform)
            DesiredLeftPitch = (DesiredLeftPitch - (PitchPerPlayer * Player.MovementWorldUp.Z) * GetPlayerSizeWeightMultiplier(Player)) * Player.MovementWorldUp.Z;

        float DesiredRightPitch = 0.f;
        for (AHazePlayerCharacter Player : PlayersOnRightPlatform)
            DesiredRightPitch = DesiredRightPitch + (PitchPerPlayer * Player.MovementWorldUp.Z) * GetPlayerSizeWeightMultiplier(Player);

        float DesiredPitch = DesiredLeftPitch + DesiredRightPitch;

		float Velocity = FMath::Abs(PhysValue.Velocity);
		if (FMath::IsNearlyEqual(Velocity, 0.f, 0.2f))
			CurrentRotationSpeed = 0.f;
		else
			CurrentRotationSpeed = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 60.f), FVector2D(0.f, 1.f), Velocity);

		PhysValue.SpringTowards(DesiredPitch, 8.f);
		PhysValue.Update(DeltaTime);

		if (PhysValue.Value != PreviousPitch)
		{
			ScaleArmBase.SetRelativeRotation(FRotator(0.f, 0.f, PhysValue.Value));
			ScalePlatformLeft.SetWorldRotation(FRotator(0.f, ScalePlatformLeft.WorldRotation.Yaw, 0.f));
			ScalePlatformRight.SetWorldRotation(FRotator(0.f, ScalePlatformRight.WorldRotation.Yaw, 0.f));
			PreviousPitch = PhysValue.Value;
		}
    }

    float GetPlayerSizeWeightMultiplier(AHazePlayerCharacter Player)
    {
        UCharacterChangeSizeComponent ChangeSizeComp = Cast<UCharacterChangeSizeComponent>(Player.GetComponentByClass(UCharacterChangeSizeComponent::StaticClass()));

        if (ChangeSizeComp != nullptr)
        {
            if (ChangeSizeComp.CurrentSize == ECharacterSize::Small)
                return CharacterSizeWeightMultiplierValues.Small;
            if (ChangeSizeComp.CurrentSize == ECharacterSize::Medium)
                return CharacterSizeWeightMultiplierValues.Medium;
            if (ChangeSizeComp.CurrentSize == ECharacterSize::Large)
                return CharacterSizeWeightMultiplierValues.Large;
        }

        return CharacterSizeWeightMultiplierValues.Medium;
    }
}