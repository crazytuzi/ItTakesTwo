import Vino.Interactions.InteractionComponent;
import Peanuts.Spline.SplineComponent;
import Peanuts.ButtonMash.Default.ButtonMashDefault;

UCLASS(Abstract)
class AStrongman : AActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Body;

	UPROPERTY(DefaultComponent, Attach = Body)
	UStaticMeshComponent LeftArm;

	UPROPERTY(DefaultComponent, Attach = Body)
	UStaticMeshComponent RightArm;


	UPROPERTY(DefaultComponent, Attach = Body)
	USceneComponent TrackRoot;

	UPROPERTY(DefaultComponent, Attach = LeftArm)
	USceneComponent LeftHandPosition;

	UPROPERTY(DefaultComponent, Attach = RightArm)
	USceneComponent RightHandPosition;

	UPROPERTY(DefaultComponent, Attach = TrackRoot)
	UStaticMeshComponent Track;

	UPROPERTY(DefaultComponent, Attach = TrackRoot)
	UHazeSplineComponent SplineTrack;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent MarbleTrigger;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftTicklePosition;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightTicklePosition;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComponent;

	UPROPERTY()
	TSubclassOf<UHazeCapability> RequiredCapabilityType;

	bool CalledLiftRightArm;
	bool CalledLiftLeftArm;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComponent.OnActivated.AddUFunction(this, n"OnInteractionActivated");
		Capability::AddPlayerCapabilityRequest(RequiredCapabilityType.Get());
    }

    UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(RequiredCapabilityType.Get());
	}

    UFUNCTION()
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		Player.SetCapabilityAttributeObject(n"Strongman", this);
		SetControlSide(Player);
    }

	UFUNCTION(BlueprintEvent)
	void LiftLeftArm()
	{

	}

	UFUNCTION(BlueprintEvent)
	void LowerLeftArm()
	{

	}

	UFUNCTION(BlueprintEvent)
	void LiftRightArm()
	{

	}

	UFUNCTION(BlueprintEvent)
	void LowerRightArm()
	{

	}

	UFUNCTION(BlueprintEvent)
	void ResetToDefaultPosition()
	{

	}
}