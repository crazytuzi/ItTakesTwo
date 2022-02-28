import Cake.LevelSpecific.SnowGlobe.Swimming.SnowGlobeLakeDisableComponent;
import Cake.LevelSpecific.SnowGlobe.SnowFolkCrowd.SnowFolkCrowdMember;


class USnowFolkLakeDisablerVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USnowFolkLakeDisablerComponent::StaticClass();

	FLinearColor DebugColor = FLinearColor::Yellow;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
    	auto Disabler = Cast<ASnowFolkLakeDisabler>(Component.Owner);

		auto VisComp = Cast<USnowFolkLakeDisablerComponent>(Component);
		DrawWireSphere(Disabler.GetActorLocation(), VisComp.GetScaledSphereRadius(), DebugColor, 5.f, 24);

		for(auto MemberActor : Disabler.Members)
		{
			auto Member = Cast<AHazeActor>(MemberActor);
			if(Member == nullptr)
				continue;
			
			FVector Origin, Extends;
			Member.GetActorBounds(true, Origin, Extends);
			DrawWireSphere(Member.GetActorLocation(), Extends.Size(), DebugColor, 5.f, 8);
			DrawDashedLine(Disabler.GetActorLocation(), Origin, DebugColor, DashSize = 20.f);
		}
    }
}

class USnowFolkLakeDisablerComponent : USphereComponent {}
class ASnowFolkLakeDisabler : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USnowFolkLakeDisablerComponent VisualRange;
	default VisualRange.SetCollisionProfileName(n"Trigger");
	default VisualRange.bGenerateOverlapEvents = false;
	default VisualRange.SphereRadius = 5000.f;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(DefaultComponent, Attach = VisualRange)
	USnowGlobeLakeDisableComponentExtension DisableExtension;
	default DisableExtension.SphereVisualizer = VisualRange;
	default DisableExtension.DontDisableWhileVisibleTime = 1.f;
	default DisableExtension.TickDelay = 0.f;
	default DisableExtension.DisableRange = FHazeMinMax(5000, 30000.f); 

	UPROPERTY(EditInstanceOnly)
	TArray<AHazeActor> Members;

	UPROPERTY(EditInstanceOnly, Category = "EDITOR ONLY")
	TArray<TSubclassOf<AHazeActor>> ClassToPick;

	UFUNCTION(CallInEditor, Category = "EDITOR ONLY")
	void PickAllActorsOfSelectedType()
	{
		Members.Reset();

		for(auto ClassItr : ClassToPick)
		{
			if(!ClassItr.IsValid())
				return;

			TArray<AActor> FoundActors;
			GetAllActorsOfClass(ClassItr, FoundActors);

			for(auto Actor : FoundActors)
			{
				if(Actor.GetDistanceTo(this) > VisualRange.GetScaledSphereRadius())
					continue;

				if(Actor.GetLevel() != GetLevel())
					continue;

				Members.Add(Cast<AHazeActor>(Actor));
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorPostDisabled()
	{
		for(auto Member : Members)
		{
			if(Member == nullptr)
				continue;
			
			auto Crumb = UHazeCrumbComponent::Get(Member);
			if(Crumb == nullptr)
			{
				Member.DisableActor(this);
			}
			else if(Member.HasControl())
			{
				// if the actor is using a crumb component, we need to handle the deactivate using a crumb
				FHazeDelegateCrumbParams Params;
				Params.AddObject(n"Actor", Member);
				Crumb.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_DisableActor"), Params);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		for(auto Member : Members)
		{
			if(Member == nullptr)
				continue;

			auto Crumb = UHazeCrumbComponent::Get(Member);
			if(Crumb == nullptr)
			{
				Member.EnableActor(this);
			}
			else if(Member.HasControl())
			{
				// if the actor is using a crumb component, we need to handle the activation using a crumb
				FHazeDelegateCrumbParams Params;
				Params.AddObject(n"Actor", Member);
				Crumb.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_EnableActor"), Params);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	protected void Crumb_DisableActor(const FHazeDelegateCrumbData& CrumbData)
	{
		AHazeActor Member = Cast<AHazeActor>(CrumbData.GetObject(n"Actor"));
		if(Member != nullptr)
		{
			Member.DisableActor(this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	protected void Crumb_EnableActor(const FHazeDelegateCrumbData& CrumbData)
	{
		AHazeActor Member = Cast<AHazeActor>(CrumbData.GetObject(n"Actor"));
		if(Member != nullptr)
		{
			Member.EnableActor(this);
		}
	}
}