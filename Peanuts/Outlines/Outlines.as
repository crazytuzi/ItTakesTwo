import Peanuts.Outlines.Packing;
import Peanuts.Outlines.Stencil;

namespace FOutlines
{
    const FOutline Cody = FOutline(n"Cody", FLinearColor(0.493354f, 0.994792f, 0.0513f, 1.0f), 0.9f, 0.5f, EOutlineDisplayMode::OccludedPortion, EOutlineViewport::May, 5.0f);
    const FOutline May = FOutline(n"May", FLinearColor(0.04197f, 0.386287f, 0.994792f, 1.0f), 0.9f, 0.5f, EOutlineDisplayMode::OccludedPortion, EOutlineViewport::Cody, 5.0f);

	const FOutline Nothing = FOutline(n"May", FLinearColor(0.04197f, 0.386287f, 0.994792f, 1.0f), 0.9f, 0.5f, EOutlineDisplayMode::OccludedPortion, EOutlineViewport::Neither, 5.0f);

    const FOutline Red = FOutline(n"Red", FLinearColor(1.0f, 0.314f, 0.314f, 1.0f), 0.9f, 0.5f, EOutlineDisplayMode::All, EOutlineViewport::Both, 10.0f);
    const FOutline Blue = FOutline(n"Blue", FLinearColor(0.576f, 0.769f, 0.49f, 1.0f), 0.9f, 0.5f, EOutlineDisplayMode::All, EOutlineViewport::Both, 10.0f);
    const FOutline Green = FOutline(n"Green", FLinearColor(0.294f, 0.098f, 0.91f, 1.0f), 0.9f, 0.5f, EOutlineDisplayMode::All, EOutlineViewport::Both, 10.0f);
    const FOutline Yellow = FOutline(n"Yellow", FLinearColor(1.0f, 0.82f, 0.404f, 1.0f), 0.9f, 0.5f, EOutlineDisplayMode::All, EOutlineViewport::Both, 10.0f);

    const FOutline Red_NoOutline = FOutline(n"Red_NoOutline", FLinearColor(1.0f, 0.314f, 0.314f, 1.0f), 0.0f, 0.5f, EOutlineDisplayMode::All, EOutlineViewport::Both, 10.0f);
    const FOutline Blue_NoOutline = FOutline(n"Blue_NoOutline", FLinearColor(0.576f, 0.769f, 0.49f, 1.0f), 0.0f, 0.5f, EOutlineDisplayMode::All, EOutlineViewport::Both, 10.0f);

    UFUNCTION(BlueprintPure)
    FOutline GetCodyOutline(EOutlineViewport Viewport = EOutlineViewport::May)
    { 
        FOutline Result = Cody;
        Result.Viewport = Viewport;
        return Result; 
    }

    UFUNCTION(BlueprintPure)
    FOutline GetMayOutline(EOutlineViewport Viewport = EOutlineViewport::Cody)
    { 
        FOutline Result = May;
        Result.Viewport = Viewport;
        return Result; 
    }

    UFUNCTION(BlueprintPure)
    FOutline GetRedOutline() { return Red; }

    UFUNCTION(BlueprintPure)
    FOutline GetBlueOutline() { return Blue; }

    UFUNCTION(BlueprintPure)
    FOutline GetGreenOutline() { return Green; }

    UFUNCTION(BlueprintPure)
    FOutline GetYellowOutline() { return Yellow; }

    UFUNCTION(BlueprintPure)
    FOutline GetRed_NoOutlineOutline() { return Red_NoOutline; }

    UFUNCTION(BlueprintPure)
    FOutline GetBlue_NoOutlineOutline() { return Blue_NoOutline; }
}

struct FOutline
{
    FOutline(
        FName Tag, 
        FLinearColor Color, 
        float BorderOpacity = 0.9f, 
        float FillOpacity = 0.5f, 
        EOutlineDisplayMode DisplayMode = EOutlineDisplayMode::All, 
        EOutlineViewport Viewport = EOutlineViewport::Both,
        float BorderWidth = 5.0f)
    {
        this.Tag = Tag;
        this.Color = Color;
        this.BorderOpacity = BorderOpacity;
        this.FillOpacity = FillOpacity;
        this.DisplayMode = DisplayMode;
        this.Viewport = Viewport;
        this.BorderWidth = BorderWidth;
		Sanitize();
    }

	void Sanitize()
	{
        BorderOpacity = FMath::Clamp(BorderOpacity, 0.0f, 1.0f);
        FillOpacity = FMath::Clamp(FillOpacity, 0.0f, 1.0f);
	}

    UPROPERTY()
    FName Tag = n"Default Outline";

    UPROPERTY()
    FLinearColor Color = FLinearColor(0.651f, 0.196f, 0.235f, 1.0f);

    UPROPERTY()
    float BorderOpacity = 0.9f;

    UPROPERTY()
    float FillOpacity = 0.5f;

    UPROPERTY()
    EOutlineDisplayMode DisplayMode = EOutlineDisplayMode::All;

    UPROPERTY()
    EOutlineViewport Viewport= EOutlineViewport::Both;

    UPROPERTY()
    float BorderWidth;

    
    bool opEquals(FOutline Other)
    {
        return (Other.Tag == Tag && 
                Other.Color == Color &&
                Other.BorderOpacity == BorderOpacity &&
                Other.FillOpacity == FillOpacity &&
                Other.DisplayMode == DisplayMode &&
                Other.Viewport == Viewport &&
                Other.BorderWidth == BorderWidth);
    }

    bool opNotEquals(FOutline Other)
    {
        return !(this == Other);
    }
}

enum EOutlineDisplayMode
{
    All = 0,
    VisiblePortion = 1,
    OccludedPortion = 2,
}

enum EOutlineViewport
{
    Cody = 0,
    May = 1,
    Both = 2,
    Neither = 3,
}

struct FInstigatedOutline
{
	// Could save an index to an array containing outlines instead, to save a bit of memory and performance. Probably not worth the maintenance though.
    FOutline Outline;
    
    UObject Instigator;

    bool opEquals(FInstigatedOutline Other)
    {
        return ((Other.Instigator == Instigator) && (Other.Outline == Outline));
    }
    bool opNotEquals(FInstigatedOutline Other)
    {
        return !(this == Other);
    }
}

struct FOutlineInstigators
{
    TArray<FInstigatedOutline> Outlines;
}

struct FOutlineDebugData
{
	UPROPERTY()
	TArray<UPrimitiveComponent> Meshes;

	UPROPERTY()
	FOutline Outline;
}

class UOutlinesComponent : UActorComponent
{
    // All meshes which should have outlines
    TMap<UPrimitiveComponent, FOutline> ActiveOutlinesMap;

    // Material indices by tag
    TMap<FName, int> TagIndexMap;
	const int HighestTagIndex = 15; // Tag indices must be 0..HighestTagIndex

    TMap<UPrimitiveComponent, FOutlineInstigators> AllInstigatedOutlines;

    UPROPERTY()
    UObject OutlineMaterial = Asset("/Game/Effects/PostProcess/LevelSpecific/Post_Everything.Post_Everything");

    UPROPERTY()
    UMaterialInstanceDynamic OutlineMaterialDynamic;
    
    UPROPERTY()
    TSubclassOf<UHazeUserWidget> OtherPlayerIndicatorWidget;

    UFUNCTION()
    void Init()
    {
        OutlineMaterialDynamic = Material::CreateDynamicMaterialInstance(Cast<UMaterialInstance>(OutlineMaterial));
    }

    void Reset()
    {
        // Clear out all outlines, then apply the meshes of cody and may
		for (auto Outline : ActiveOutlinesMap)
		{
			SetMeshOutlineStencil(Outline.Key, false);
			SetOutlineViewport(Outline.Key, EOutlineViewport::Neither);
		}
        ActiveOutlinesMap.Empty();
		TagIndexMap.Empty();
		AllInstigatedOutlines.Empty();

        // Cody is loaded last, so both outline components are guaranteed to be created
        if (Owner == Game::GetCody())
        {
            CreateMeshOutline(Game::GetCody().Mesh, FOutlines::Cody);
            CreateMeshOutline(Game::GetMay().Mesh, FOutlines::May);
        }
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Init();
        Reset();
    }

    UFUNCTION(BlueprintOverride)
    void OnResetComponent(EComponentResetType Type)
    {
        Reset();
    }

    // Packing & Unpacking functions mirrored in MaterialMeshOutline.usf
    FLinearColor PackOutline(FOutline o)
    {
        float PackedR = PackTwoFloats(o.Color.R, o.BorderOpacity);
        float PackedG = PackTwoFloats(o.Color.G, o.FillOpacity);
        float PackedB = PackFloatAndInt(o.Color.B, o.DisplayMode, o.Viewport);
        return FLinearColor(PackedR, PackedG, PackedB, o.BorderWidth);
    }

    FOutline UnpackOutline(FLinearColor Input)
    {
        FVector2D a = UnpackTwoFloats(Input.R);
        FVector2D b = UnpackTwoFloats(Input.G);
        FVector c = UnpackFloatAndInt(Input.B);
        FOutline Result;
        Result.Color.R = a.X;
        Result.Color.G = b.X;
        Result.Color.B = c.X;

        Result.BorderOpacity = a.Y;
        Result.FillOpacity = b.Y;

        Result.DisplayMode = EOutlineDisplayMode(int(c.Y));
        Result.Viewport = EOutlineViewport(int(c.Z));

        Result.BorderWidth = Input.A;
        return Result;
    }

    void SetOutlineViewport(UPrimitiveComponent Comp, EOutlineViewport Viewport)
    {
		if(!Game::DetailModeLow) // If It's PC
			return; // disable this function so cody's outline can't be seen through may.

        if(Comp == nullptr)
            return;

        switch(Viewport)
        {
            case EOutlineViewport::Both:
            {
                Comp.SetCustomDepthRenderedForPlayer(Game::GetCody(), true);
                Comp.SetCustomDepthRenderedForPlayer(Game::GetMay(), true);
            }
            break;
            case EOutlineViewport::Neither:
            {
                Comp.SetCustomDepthRenderedForPlayer(Game::GetCody(), false);
                Comp.SetCustomDepthRenderedForPlayer(Game::GetMay(), false);
            }
            break;
            case EOutlineViewport::Cody:
            {
                Comp.SetCustomDepthRenderedForPlayer(Game::GetCody(), true);
                Comp.SetCustomDepthRenderedForPlayer(Game::GetMay(), false);
            }
            break;
            case EOutlineViewport::May:
            {
                Comp.SetCustomDepthRenderedForPlayer(Game::GetCody(), false);
                Comp.SetCustomDepthRenderedForPlayer(Game::GetMay(), true);
            }
            break;
        }
    }

    void SetMeshOutlineStencil(UPrimitiveComponent Mesh, bool Enabled, int Value = 0)
    {
        if(Mesh != nullptr)
        {
            Mesh.CustomDepthStencilValue = StencilSetOutline(Mesh.CustomDepthStencilValue, Value);
            if(!Enabled)
            {
                Mesh.CustomDepthStencilValue = StencilDisableOutline(Mesh.CustomDepthStencilValue);
            }
            Mesh.SetRenderCustomDepth(Mesh.CustomDepthStencilValue != 0);
            Mesh.MarkRenderStateDirty();
        }
    }

    int FindOrAddTagIndex(FName Tag)
    {
        if (TagIndexMap.Contains(Tag))
			return TagIndexMap[Tag];

		// New tag, find first available tag index. Must be 0..HighestTagIndex
		int TagIndex = 0;
		if (TagIndexMap.Num() > 0)
		{
			TArray<int> UsedIndices;
			UsedIndices.SetNum(TagIndexMap.Num());
			int i = 0;
			for (auto Slot : TagIndexMap)
			{
				UsedIndices[i] = Slot.Value;
				i++;
			}
			UsedIndices.Sort();
			for (TagIndex = 0; TagIndex < UsedIndices.Num(); TagIndex++) 
			{
				// Was this index unused?
				if (UsedIndices[TagIndex] != TagIndex)
					break;
			};
			ensure(TagIndex <= HighestTagIndex);
		}
        TagIndexMap.Add(Tag, TagIndex);
        return TagIndex;
    }

	void UpdateTagIndices()
	{
		// Check if a tag has been removed from all active outlines
		TMap<FName, bool> UsedTags;
		for (auto ActiveSlot : ActiveOutlinesMap)
		{
			UsedTags.Add(ActiveSlot.Value.Tag, true);
		}
		TArray<FName> RemovedTags;
		for (auto TagSlot : TagIndexMap)
		{
			// Remove any tag which no longer have any active outlines using it
			if (!UsedTags.Contains(TagSlot.Key))
				RemovedTags.Add(TagSlot.Key);		
		}
		for (FName RemovedTag : RemovedTags)
		{
			TagIndexMap.Remove(RemovedTag);					
		}
	}

	private void SetActiveOutline(UPrimitiveComponent Mesh, int TagIndex, FOutline Outline)
	{
		ActiveOutlinesMap.Add(Mesh, Outline);                       
		OutlineMaterialDynamic.SetVectorParameterValue(FName("OutlineData" + TagIndex), FLinearColor(Outline.Color.R, Outline.Color.G, Outline.Color.B, Outline.FillOpacity));
		OutlineMaterialDynamic.SetVectorParameterValue(FName("OutlineData" + TagIndex + "_2"), FLinearColor(Outline.DisplayMode, Outline.Viewport, Outline.BorderOpacity, Outline.BorderWidth));
		SetMeshOutlineStencil(Mesh, true, TagIndex);
		SetOutlineViewport(Mesh, Outline.Viewport);
	}

    void CreateMeshOutlines(TArray<UPrimitiveComponent> Meshes, FOutline Outline, UObject Instigator)
    {
		// Initialize if this is the first outline to be added
		if(OutlineMaterialDynamic == nullptr)
			Init();

		// Make sure all outline values are within suitable ranges
		FOutline NewOutline = Outline;
		NewOutline.Sanitize();

		// We are only allowed to have a set number of tags
		bool bNewTag = !TagIndexMap.Contains(NewOutline.Tag);
        if(bNewTag && (TagIndexMap.Num() >= HighestTagIndex))
        {
            Print("ERROR. Can't have more than " + (HighestTagIndex + 1) + " outline tags.");
            return;
        }

        // Make sure we have a valid tag index
		bool bChangedTags = bNewTag;
        int TagIndex = FindOrAddTagIndex(NewOutline.Tag);

		// As tags are the way outlines are grouped, we will set this outline for any other 
		// meshes that have that tag even though they were not supplied as a parameter. 
		// E.g. if creating a new outline for May, we want her attachments to have the same 
		// outline even though these are not given as a parameter.
		// Note that this will give these meshes an active outline even though the outline 
		// matching the tag might not be active.
		TArray<UPrimitiveComponent> TaggedMeshes = Meshes;
		for (auto Slot : AllInstigatedOutlines)
		{
			UPrimitiveComponent Mesh = Slot.Key;
			if (!TaggedMeshes.Contains(Mesh))
			{
				const TArray<FInstigatedOutline>& MeshOutlines = Slot.Value.Outlines;
				for (FInstigatedOutline Instigated : MeshOutlines)
				{
					if (Instigated.Outline.Tag == NewOutline.Tag)
					{
						TaggedMeshes.AddUnique(Mesh);
						break;
					}
				}
			}
		}

		for (UPrimitiveComponent Mesh : TaggedMeshes)
	    {
			// Add current outline to those wanting an outline for mesh
			TArray<FInstigatedOutline>& Outlines = AllInstigatedOutlines.FindOrAdd(Mesh).Outlines;
			FInstigatedOutline NewSlot;
			NewSlot.Outline = NewOutline; 
			NewSlot.Instigator = Instigator;

			//Remove any previous identical slot before adding the new, as a later added outline has prio over an earlier one
			Outlines.Remove(NewSlot);
			Outlines.Add(NewSlot);

			FOutline PrevOutline;
			PrevOutline.Tag = NAME_None; // So it'll differ from given outline tag if this is a newly added mesh
			if (!ActiveOutlinesMap.Find(Mesh, PrevOutline) || (PrevOutline != NewOutline))
			{
				// We're adding a new outline for mesh or changing the old one.
				SetActiveOutline(Mesh, TagIndex, NewOutline);
				bChangedTags = bChangedTags || (PrevOutline.Tag != NewOutline.Tag);
			}
		}
		if (bChangedTags)
			UpdateTagIndices();    
    }

    // Removes any outlines with the given tag and created by given instigator
    UFUNCTION()
    void RemoveMeshOutline(FName Tag, UObject Instigator)
    {
		bool bChangedTags = false;
        for (auto Slot : AllInstigatedOutlines)
        {
			// Remove any matching outline entries
			TArray<FInstigatedOutline>& Outlines = Slot.Value.Outlines;
			bool bRemovedCurrent = false;
            for (int i = Outlines.Num() - 1; i >= 0; i--)
            {
                if ((Outlines[i].Outline.Tag == Tag) && 
                    (Outlines[i].Instigator == Instigator))
                {
                    if (i == Outlines.Num() - 1)
						bRemovedCurrent = true;
					Outlines.RemoveAt(i);	
                }
            }

			// Do we need to update active outline for this mesh?
			if (bRemovedCurrent)
				UpdateActiveOutlines(Slot.Key, Outlines, bChangedTags);
        }

		if (bChangedTags)
			UpdateTagIndices();    
	}

    // Removes all outlines from this mesh but does not remove the outline itself unless it no longer has any meshes assgned
    UFUNCTION()
    void RemoveMeshOutlineFromMesh(UPrimitiveComponent Mesh, UObject Instigator)
    {
		if (!AllInstigatedOutlines.Contains(Mesh))
			return;
		
		// Get all outlines for the given mesh and remove the ones set by given instigator
		TArray<FInstigatedOutline>& Outlines = AllInstigatedOutlines[Mesh].Outlines;
		bool bRemovedCurrent = false;
		for (int i = Outlines.Num() - 1; i >= 0; i--)
		{
			if (Outlines[i].Instigator == Instigator)
			{
				if (i == Outlines.Num() - 1)
					bRemovedCurrent = true;
				Outlines.RemoveAt(i);	
			}	
		}

		// Do we need to update active outline for this mesh?
		bool bChangedTags = false;
		if (bRemovedCurrent)
			UpdateActiveOutlines(Mesh, Outlines, bChangedTags);

		if (bChangedTags)
			UpdateTagIndices();    
    }

	// Update the active outline for this mesh.
	void UpdateActiveOutlines(UPrimitiveComponent Mesh, const TArray<FInstigatedOutline>& Outlines, bool& bChangedTags)
	{
		if (!ensure(ActiveOutlinesMap.Contains(Mesh)))
			return;

		if (Outlines.Num() == 0)
		{
			// No outlines left, remove mesh
			SetMeshOutlineStencil(Mesh, false);
			SetOutlineViewport(Mesh, EOutlineViewport::Neither);
			ActiveOutlinesMap.Remove(Mesh);
			bChangedTags = true;
		}
		else 
		{
			// Fall back to the recentmost outline
			const FOutline& Outline = Outlines.Last().Outline;
			if (Outline != ActiveOutlinesMap[Mesh])
			{
				if (Outline.Tag != ActiveOutlinesMap[Mesh].Tag)
					bChangedTags = true;	
				int TagIndex = FindOrAddTagIndex(Outline.Tag);
				SetActiveOutline(Mesh, TagIndex, Outline);
			}
		}
	}

	UFUNCTION(BlueprintPure)
	TArray<FOutlineDebugData> GetActiveOutlinesDebugData()
	{
		TMap<FName, FOutlineDebugData> DebugData;
		for (auto Slot : ActiveOutlinesMap)
		{
			DebugData.FindOrAdd(Slot.Value.Tag).Outline = Slot.Value;
			DebugData[Slot.Value.Tag].Meshes.AddUnique(Slot.Key);
		}
		TArray<FOutlineDebugData> Res;
		for (auto Slot : DebugData)
		{
			Res.Add(Slot.Value);			
		}
		return Res;
	}
};

//DEPRECATED: Use CreateNewMeshOutline instead.
UFUNCTION(meta=(DeprecatedFunction, DeprecationMessage = "Use CreateNewMeshOutline instead."))
void CreateMeshOutline(UPrimitiveComponent Mesh, FOutline Outline){
    UOutlinesComponent CodyComponent = UOutlinesComponent::Get(Game::GetCody());
    UOutlinesComponent MayComponent = UOutlinesComponent::Get(Game::GetMay());
    TArray<UPrimitiveComponent> Meshes = TArray<UPrimitiveComponent>();
    Meshes.Add(Mesh);
    CodyComponent.CreateMeshOutlines(Meshes, Outline, nullptr);
    MayComponent.CreateMeshOutlines(Meshes, Outline, nullptr);}
//DEPRECATED: Use AddMeshToPlayerOutline instead.
UFUNCTION(meta=(DeprecatedFunction, DeprecationMessage = "Use AddMeshToPlayerOutline instead."))
void CreateMeshOutlineBasedOnPlayer(UPrimitiveComponent Mesh, AHazePlayerCharacter Player){
    CreateMeshOutline(Mesh, Player.IsMay() ? FOutlines::May : FOutlines::Cody);}
//DEPRECATED: Use RemoveMeshFromPlayerOutline or RemoveOutlineFromMesh instead.
UFUNCTION(meta=(DeprecatedFunction, DeprecationMessage = "Use RemoveMeshFromAllOutlines instead."))
void RemoveMeshOutlineFromMesh(UPrimitiveComponent Mesh){
    UOutlinesComponent CodyComponent = UOutlinesComponent::Get(Game::GetCody());
    UOutlinesComponent MayComponent = UOutlinesComponent::Get(Game::GetMay());
    CodyComponent.RemoveMeshOutlineFromMesh(Mesh, nullptr);
    MayComponent.RemoveMeshOutlineFromMesh(Mesh, nullptr);}
//DEPRECATED: Use RemoveOutlineByTag instead.
UFUNCTION(meta=(DeprecatedFunction, DeprecationMessage = "Use RemoveOutlineByTag instead."))
void RemoveMeshOutline(FName Tag){
    UOutlinesComponent CodyComponent = UOutlinesComponent::Get(Game::GetCody());
    UOutlinesComponent MayComponent = UOutlinesComponent::Get(Game::GetMay());
    CodyComponent.RemoveMeshOutline(Tag, nullptr);
    MayComponent.RemoveMeshOutline(Tag, nullptr);}



// For Outline default value use GetCodyOutline, GetMayOutline, etc...
UFUNCTION()
void CreateNewMeshOutline(UPrimitiveComponent Mesh, FOutline Outline, UObject Instigator)
{
    if (Mesh == nullptr)
        return;

    // Creates a new outline and adds it to may and cody'NewOutlineSlot viewports
    UOutlinesComponent CodyComponent = UOutlinesComponent::Get(Game::GetCody());
    UOutlinesComponent MayComponent = UOutlinesComponent::Get(Game::GetMay());

    TArray<UPrimitiveComponent> Meshes = TArray<UPrimitiveComponent>();
    Meshes.Add(Mesh);
    CodyComponent.CreateMeshOutlines(Meshes, Outline, Instigator);
    MayComponent.CreateMeshOutlines(Meshes, Outline, Instigator);
}

UFUNCTION()
void CreateNewMeshOutlineOverrideTag(UPrimitiveComponent Mesh, FOutline Outline, UObject Instigator, FName Tag)
{
	if (Mesh == nullptr)
		return;

	FOutline NewOutline = Outline;
	NewOutline.Tag = Tag;

    // Creates a new outline and adds it to may and cody'NewOutlineSlot viewports
    UOutlinesComponent CodyComponent = UOutlinesComponent::Get(Game::GetCody());
    UOutlinesComponent MayComponent = UOutlinesComponent::Get(Game::GetMay());

    TArray<UPrimitiveComponent> Meshes = TArray<UPrimitiveComponent>();
    Meshes.Add(Mesh);
    CodyComponent.CreateMeshOutlines(Meshes, NewOutline, Instigator);
    MayComponent.CreateMeshOutlines(Meshes, NewOutline, Instigator);
}

UFUNCTION()
void RemoveOutlineByTag(FName Tag, UObject Instigator)
{
    // Removes outlines by tag from may and cody'NewOutlineSlot viewports
    UOutlinesComponent CodyComponent = UOutlinesComponent::Get(Game::GetCody());
    UOutlinesComponent MayComponent = UOutlinesComponent::Get(Game::GetMay());
    CodyComponent.RemoveMeshOutline(Tag, Instigator);
    MayComponent.RemoveMeshOutline(Tag, Instigator);
}

UFUNCTION()
void RemoveOutlineFromMesh(UPrimitiveComponent Mesh, UObject Instigator)
{
    // Removes outlines from both may and cody'NewOutlineSlot viewports
    UOutlinesComponent CodyComponent = UOutlinesComponent::Get(Game::GetCody());
    UOutlinesComponent MayComponent = UOutlinesComponent::Get(Game::GetMay());
    CodyComponent.RemoveMeshOutlineFromMesh(Mesh, Instigator);
    MayComponent.RemoveMeshOutlineFromMesh(Mesh, Instigator);
}

UFUNCTION()
void AddMeshToPlayerOutline(UPrimitiveComponent Mesh, AHazePlayerCharacter Player, UObject Instigator)
{
    CreateNewMeshOutline(Mesh, Player.IsMay() ? FOutlines::May : FOutlines::Cody, Instigator);
}

UFUNCTION()
void RemoveMeshFromPlayerOutline(UPrimitiveComponent Mesh, UObject Instigator)
{
    // Removes outlines from both may and cody'NewOutlineSlot viewports
    UOutlinesComponent CodyComponent = UOutlinesComponent::Get(Game::GetCody());
    UOutlinesComponent MayComponent = UOutlinesComponent::Get(Game::GetMay());
    CodyComponent.RemoveMeshOutlineFromMesh(Mesh, Instigator);
    MayComponent.RemoveMeshOutlineFromMesh(Mesh, Instigator);
}





//// Fucntion used to test robustness of the outline system.
//UFUNCTION()
//void OutlineTest(UPrimitiveComponent Mesh1, UPrimitiveComponent Mesh2, UPrimitiveComponent Mesh3)
//{
//
//  
//  CreateMeshOutline(Game::GetCody().Mesh, FOutlines::Cody);
//  CreateMeshOutline(Game::GetMay().Mesh, FOutlines::May);
//
//  //int stencil = 0;
//  //stencil = StencilSetOutline(stencil, 5);
//  //Print("outline: " + StencilGetOutline(stencil));
//  //stencil = StencilSetEffect(stencil, true);
//  //Print("outline: " + StencilGetOutline(stencil));
//  //stencil = StencilDisableOutline(stencil);
//  //Print("outline: " + StencilGetOutline(stencil));
//  //stencil = StencilSetOutline(stencil, 5);
//  //Print("outline: " + StencilGetOutline(stencil));
//  
//
//
//  //CreateMeshOutline(Mesh1, FOutline(n"test1", FLinearColor(0.8f, 0.2f, 0.1f, 1.0f), BorderOpacity = 0.9f, FillOpacity = 0.5f, DisplayMode = EOutlineDisplayMode::All, BorderWidth = 10));
//  //CreateMeshOutline(Mesh2, FOutline(n"test2", FLinearColor(0.1f, 0.8f, 0.2f, 1.0f), BorderOpacity = 0.9f, FillOpacity = 0.5f, DisplayMode = EOutlineDisplayMode::VisiblePortion, BorderWidth = 100));
//
//  //CreateMeshOutline(Mesh3, FOutline(n"test3", FLinearColor(0.2f, 0.1f, 0.8f, 1.0f), BorderOpacity = 0.9f, FillOpacity = 0.5f, DisplayMode = EOutlineDisplayMode::OccludedPortion, BorderWidth = 10));
//  //CreateMeshOutline(Mesh3, FOutlines::May);
//}
