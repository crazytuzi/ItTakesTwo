import Peanuts.Actor.ActorCommonEvents;
import Vino.AI.Scenepoints.ScenepointComponent;
import Vino.AI.Scenepoints.ScenepointActor;

class AWaspFormationScenepoint : AScenepointActorBase
{
	default Billboard.Sprite = Asset("/Engine/EngineResources/AICON-Red.AICON-Red");

	UPROPERTY(EditInstanceOnly, BlueprintHidden, meta = (MakeEditWidget = true), Category = "Formation")
	FVector SpawnLocation = FVector(400.f, 0.f, -2000.f);

	UPROPERTY(EditInstanceOnly, BlueprintHidden, meta = (MakeEditWidget = true), Category = "Formation")
	FVector Destination = FVector(3400.f, 0.f, 0.f);

	UPROPERTY(EditInstanceOnly, BlueprintHidden, meta = (MakeEditWidget = true), Category = "Formation")
	FVector FleeLocation = FVector(3000.f, 0.f, -2000.f);

	UPROPERTY(DefaultComponent, NotVisible, BlueprintHidden, Category = "Editor Visualization")
	UArrowComponent FormationDirection;
	default FormationDirection.RelativeLocation = FVector(15.f, 0.f, 0.f);
	default FormationDirection.RelativeRotation = FRotator::ZeroRotator;
	default FormationDirection.ArrowColor = FLinearColor::Red;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UWaspFormationScenepointComponent FormationComp;

	FOnConstructionScript OnConstructionScript;
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FormationDirection.RelativeRotation = Destination.Rotation();
		FormationDirection.RelativeLocation = FormationDirection.RelativeRotation.Vector() * 15.f;
		FormationComp.LocalDestination = Destination;
		FormationComp.LocalSpawnLocation = SpawnLocation;
		FormationComp.LocalFleeLocation = FleeLocation;

		OnConstructionScript.Broadcast(this);
	}

	UFUNCTION()
	UScenepointComponent GetScenepoint()
	{
		return FormationComp;
	};
}

class UWaspFormationScenepointComponent : UScenepointComponent
{
	default Radius = 400.f;

	UPROPERTY(NotVisible, BlueprintHidden)
	FVector LocalDestination;
	UPROPERTY(NotVisible, BlueprintHidden)
	FVector LocalSpawnLocation;
	UPROPERTY(NotVisible, BlueprintHidden)
	FVector LocalFleeLocation;

	FVector LocalDestinationDirection = FVector::ForwardVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LocalDestinationDirection = LocalDestination.GetSafeNormal();
	}

	UFUNCTION()
	FVector GetFormationDestination() property
	{
		return GetWorldTransform().TransformPosition(LocalDestination);
	}
	UFUNCTION()
	FVector GetFormationSpawnLocation() property
	{
		return GetWorldTransform().TransformPosition(LocalSpawnLocation);
	}
	UFUNCTION()
	FVector GetFormationFleeLocation() property
	{
		// Hardcode additional flee offset to ensure we can't see wasps unspawn
		FVector Offset = FVector(-1000.f, 0.f, 0.f);
		return GetWorldTransform().TransformPosition(LocalFleeLocation + Offset);
	}
	UFUNCTION()
	FVector GetFormationDirection() property
	{
		return GetWorldTransform().TransformVector(LocalDestinationDirection);
	}
}