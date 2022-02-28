import Rice.TemporalLog.TemporalLogStatics;
import Vino.Movement.Components.MovementComponent;

class UDebugMovementSurfaceCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityTags.Add(n"DebugMovement");
	default TickGroup = ECapabilityTickGroups::Input;
    default CapabilityDebugCategory = n"Debug";

    UHazeMovementComponent MoveComp;
	UMovementSettings MoveSettings;

    UMaterial DebugMaterial;

    UMaterialInstanceDynamic SurfaceInstance;
    UMaterialInstanceDynamic NonWalkableInstance;

	bool bWantsActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DebugMaterial = Cast<UMaterial>(LoadObject(this, "/Game/MasterMaterials/Debug/SurfaceClassifyMaterial.SurfaceClassifyMaterial"));

		if (DebugMaterial != nullptr)
		{
			SurfaceInstance = Material::CreateDynamicMaterialInstance(DebugMaterial, n"Surface");
			NonWalkableInstance = Material::CreateDynamicMaterialInstance(DebugMaterial, n"NonWalkable");
			NonWalkableInstance.SetScalarParameterValue(n"WalkableAngle", 0.f);
		}

		MoveSettings = UMovementSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"ShowSurface", "ShowSurface");
		Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"Movement");
	}

	UFUNCTION()
	void ShowSurface()
	{
		bWantsActive = true;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (DebugMaterial == nullptr) 
			return EHazeNetworkActivation::DontActivate;

		if (!bWantsActive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}
 
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TArray<UPrimitiveComponent> PrimComponents;

		TSubclassOf<AActor> ActorClass(AActor::StaticClass());
		TArray<AActor> Actors;
		Gameplay::GetAllActorsOfClass(ActorClass, Actors);

		for(AActor Actor : Actors)
		{
			Actor.GetComponentsByClass(PrimComponents);
			for(UPrimitiveComponent Comp : PrimComponents)
			{
				if (Comp.GetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter) != ECollisionResponse::ECR_Block)
					continue;

				for(int i=0; i<Comp.GetNumMaterials(); ++i)
				{
					if (Comp.HasTag(n"Walkable"))
						Comp.SetMaterial(i, SurfaceInstance);
					else
						Comp.SetMaterial(i, NonWalkableInstance);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SurfaceInstance.SetScalarParameterValue(n"WalkableAngle", MoveSettings.WalkableSlopeAngle);
		SurfaceInstance.SetScalarParameterValue(n"CeilingAngle", MoveSettings.CeilingAngle);

		NonWalkableInstance.SetScalarParameterValue(n"CeilingAngle", MoveSettings.CeilingAngle);
	}
}
