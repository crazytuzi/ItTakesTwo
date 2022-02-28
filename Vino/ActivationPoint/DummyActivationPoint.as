

class UDummyActivationPointBase : UHazeActivationPoint
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default ValidationType = EHazeActivationPointActivatorType::None;
	default ValidationIdentifier = EHazeActivationPointIdentifierType::Default;
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 1000.f);
	default BiggestDistanceType = EHazeActivationPointDistanceType::Selectable;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	#if TEST
		devEnsure(ValidationType == EHazeActivationPointActivatorType::Cody
		|| ValidationType == EHazeActivationPointActivatorType::May, 
			"DummyActivationPoint " + GetName() + " on " + GetOwner() + " requires an exclusive ValidationType");
		
		TArray<UActorComponent> ActivationPoints;
		Owner.GetAllComponents(UHazeActivationPoint::StaticClass(), ActivationPoints);
		devEnsure(ActivationPoints.Num() > 1, 
			"DummyActivationPoint " + GetName() + " on " + GetOwner() + " requires a real activation point");
	#endif

		Capability::AddPlayerCapabilityRequest(UDummyActivationPointCapability::StaticClass());
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Capability::RemovePlayerCapabilityRequest(UDummyActivationPointCapability::StaticClass());
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{	
		if(ValidationType == EHazeActivationPointActivatorType::Cody
		|| ValidationType == EHazeActivationPointActivatorType::May)
			return EHazeActivationPointStatusType::Valid;

		return EHazeActivationPointStatusType::InvalidAndHidden;
	}
}

class UDummyActivationPointCapability : UHazeCapability
{
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.UpdateActivationPointAndWidgets(UDummyActivationPointBase::StaticClass());
	}
}