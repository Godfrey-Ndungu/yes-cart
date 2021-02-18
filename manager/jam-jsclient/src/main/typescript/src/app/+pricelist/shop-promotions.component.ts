/*
 * Copyright 2009 Inspire-Software.com
 *
 *    Licensed under the Apache License, Version 2.0 (the 'License');
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an 'AS IS' BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */
import { Component, OnInit, OnDestroy, ViewChild } from '@angular/core';
import { ShopEventBus, PricingService, UserEventBus, I18nEventBus, Util } from './../shared/services/index';
import { PromotionTestConfigComponent } from './components/index';
import { ModalComponent, ModalResult, ModalAction } from './../shared/modal/index';
import { AttributeVO, PromotionVO, ShopVO, Pair, CartVO, PromotionTestVO, SearchResultVO } from './../shared/model/index';
import { FormValidationEvent, Futures, Future } from './../shared/event/index';
import { Config } from './../../environments/environment';
import { UiUtil } from './../shared/ui/index';
import { LogUtil } from './../shared/log/index';
import { StorageUtil } from './../shared/storage/index';

@Component({
  selector: 'cw-shop-promotions',
  templateUrl: 'shop-promotions.component.html',
})

export class ShopPromotionsComponent implements OnInit, OnDestroy {

  private static PROMOTIONS:string = 'promotions';
  private static PROMOTION:string = 'promotion';
  private static PROMOTIONS_TEST:string = 'promotionstest';

  private static COOKIE_SHOP:string = 'ADM_UI_PROMO_SHOP';
  private static COOKIE_CURRENCY:string = 'ADM_UI_PROMO_CURR';

  private static _selectedShopCode:string;
  private static _selectedShop:ShopVO;
  private static _selectedCurrency:string;

  private static _promoTypes:Pair<AttributeVO, boolean>[] = [];

  private static _promoActions:Pair<AttributeVO, boolean>[] = [];

  private static _promoOptions:any = {};

  public searchHelpShow:boolean = false;
  public forceShowAll:boolean = false;
  public viewMode:string = ShopPromotionsComponent.PROMOTIONS;

  public promotions:SearchResultVO<PromotionVO>;
  public promotionFilter:string;
  public promotionFilterRequired:boolean = true;

  private delayedFiltering:Future;
  private delayedFilteringMs:number = Config.UI_INPUT_DELAY;

  public selectedPromotion:PromotionVO;

  public promotionEdit:PromotionVO;

  @ViewChild('deleteConfirmationModalDialog')
  private deleteConfirmationModalDialog:ModalComponent;

  @ViewChild('disableConfirmationModalDialog')
  private disableConfirmationModalDialog:ModalComponent;

  public deleteValue:String;

  public loading:boolean = false;

  public changed:boolean = false;
  public validForSave:boolean = false;
  public validForSaveAndDisabled:boolean = false;

  @ViewChild('selectShopModalDialog')
  private selectShopModalDialog:ModalComponent;

  @ViewChild('selectCurrencyModalDialog')
  private selectCurrencyModalDialog:ModalComponent;

  public testCart:CartVO;

  @ViewChild('runTestModalDialog')
  private runTestModalDialog:PromotionTestConfigComponent;

  private userSub:any;

  constructor(private _promotionService:PricingService) {
    LogUtil.debug('ShopPromotionsComponent constructed');
    this.promotions = this.newSearchResultInstance();
  }

  get selectedShop():ShopVO {
    return ShopPromotionsComponent._selectedShop;
  }

  set selectedShop(selectedShop:ShopVO) {
    ShopPromotionsComponent._selectedShop = selectedShop;
  }

  get selectedShopCode(): string {
    return ShopPromotionsComponent._selectedShopCode;
  }

  set selectedShopCode(value: string) {
    ShopPromotionsComponent._selectedShopCode = value;
  }

  get selectedCurrency():string {
    return ShopPromotionsComponent._selectedCurrency;
  }

  set selectedCurrency(selectedCurrency:string) {
    ShopPromotionsComponent._selectedCurrency = selectedCurrency;
  }


  newPromotionInstance():PromotionVO {
    return {
      promotionId: 0, code: '', shopCode: this.selectedShop.code, currency: this.selectedCurrency,
      rank: 500, name: null,  description: null,
      displayNames: [], displayDescriptions: [],
      promoType: 'O', promoAction: 'P',
      eligibilityCondition: null, promoActionContext: null,
      couponTriggered: false, canBeCombined: true,
      enabled: false, enabledFrom: null, enabledTo: null,
      tag: null
    };
  }

  newSearchResultInstance():SearchResultVO<PromotionVO> {
    return {
      searchContext: {
        parameters: {
          filter: [],
          types: [],
          actions: []
        },
        start: 0,
        size: Config.UI_TABLE_PAGE_SIZE,
        sortBy: null,
        sortDesc: false
      },
      items: [],
      total: 0
    };
  }


  get promoTypes():Pair<AttributeVO, boolean>[] {
    return ShopPromotionsComponent._promoTypes;
  }

  set promoTypes(value:Pair<AttributeVO, boolean>[]) {
    ShopPromotionsComponent._promoTypes = value;
  }

  get promoActions():Pair<AttributeVO, boolean>[] {
    return ShopPromotionsComponent._promoActions;
  }

  set promoActions(value:Pair<AttributeVO, boolean>[]) {
    ShopPromotionsComponent._promoActions = value;
  }

  get promoOptions(): any {
    return ShopPromotionsComponent._promoOptions;
  }

  set promoOptions(value: any) {
    ShopPromotionsComponent._promoOptions = value;
  }

  getAttributeName(attr:AttributeVO):string {

    let lang = I18nEventBus.getI18nEventBus().current();
    let i18n = attr.displayNames;
    let def = attr.name != null ? attr.name : attr.code;

    return UiUtil.toI18nString(i18n, def, lang);

  }



  ngOnInit() {
    LogUtil.debug('ShopPromotionsComponent ngOnInit');

    this.onRefreshHandler();

    this.userSub = UserEventBus.getUserEventBus().userUpdated$.subscribe(user => {
      this.presetFromCookie();
    });

    let that = this;
    this.delayedFiltering = Futures.perpetual(function() {
      that.getFilteredPromotions();
    }, this.delayedFilteringMs);

  }

  ngOnDestroy() {
    LogUtil.debug('ShopPromotionsComponent ngOnDestroy');
    if (this.userSub) {
      this.userSub.unsubscribe();
    }
  }

  presetFromCookie() {

    if (this.selectedShop == null) {
      let shopCode = StorageUtil.readValue(ShopPromotionsComponent.COOKIE_SHOP, null);
      if (shopCode != null) {
        let shops = ShopEventBus.getShopEventBus().currentAll();
        if (shops != null) {
          shops.forEach(shop => {
            if (shop.code == shopCode) {
              this.selectedShop = shop;
              this.selectedShopCode = shop.code;
              LogUtil.debug('ShopPromotionsComponent ngOnInit presetting shop from cookie', shop);
            }
          });
        }
      }
    }
    if (this.selectedCurrency == null) {
      let curr = StorageUtil.readValue(ShopPromotionsComponent.COOKIE_CURRENCY, null);
      if (curr != null) {
        this.selectedCurrency = curr;
        LogUtil.debug('ShopPromotionsComponent ngOnInit presetting currency from cookie', curr);
      }
    }
    if (this.promoTypes.length == 0) {
      this._promotionService.getPromotionOptions().subscribe(res => {

        LogUtil.debug('ShopPromotionsComponent getPromotionOptions', res);

        let actions = [];

        let promoTypes: Pair<AttributeVO, boolean>[] = [];
        let promoActions: Pair<AttributeVO, boolean>[] = [];
        let promoOptions:any = {};

        res.forEach(tval => {

          promoTypes.push({first: tval.first, second: false});
          promoOptions[tval.first.val] = [];
          tval.second.forEach(aval => {
            if (actions.indexOf(aval.val) == -1) {
              promoActions.push({first: aval, second: false});
              actions.push(aval.val);
            }
            promoOptions[tval.first.val].push(aval.val);
          });

        });

        this.promoTypes = promoTypes;
        this.promoActions = promoActions;
        this.promoOptions = promoOptions;
        LogUtil.debug('ShopPromotionsComponent ngOnInit presetting options', promoTypes, promoActions, promoOptions);

      });
    }

  }


  onShopSelect() {
    LogUtil.debug('ShopPromotionsComponent onShopSelect');
    this.selectShopModalDialog.show();
  }

  onShopSelected(event:ShopVO) {
    LogUtil.debug('ShopPromotionsComponent onShopSelected');
    this.selectedShop = event;
    if (this.selectedShop != null) {
      this.selectedShopCode = event.code;
      StorageUtil.saveValue(ShopPromotionsComponent.COOKIE_SHOP, this.selectedShop.code);
    } else {
      this.selectedShopCode = null;
    }
  }

  onSelectShopResult(modalresult: ModalResult) {
    LogUtil.debug('ShopPromotionsComponent onSelectShopResult modal result is ', modalresult);
    if (this.selectedShop == null) {
      this.selectShopModalDialog.show();
    } else if (this.selectedCurrency == null) {
      this.selectCurrencyModalDialog.show();
    } else {
      this.getFilteredPromotions();
    }
  }

  onCurrencySelect() {
    LogUtil.debug('ShopPromotionsComponent onCurrencySelect');
    this.selectCurrencyModalDialog.show();
  }

  onCurrencySelected(event:string) {
    LogUtil.debug('ShopPromotionsComponent onCurrencySelected');
    this.selectedCurrency = event;
    if (this.selectedCurrency != null) {
      StorageUtil.saveValue(ShopPromotionsComponent.COOKIE_CURRENCY, this.selectedCurrency);
    }
  }

  onSelectCurrencyResult(modalresult: ModalResult) {
    LogUtil.debug('ShopPromotionsComponent onSelectCurrencyResult modal result is ', modalresult);
    if (this.selectedCurrency == null) {
      this.selectCurrencyModalDialog.show();
    } else {
      this.getFilteredPromotions();
    }
  }

  onTestRules() {
    LogUtil.debug('ShopPromotionsComponent onTestRules');
    this.runTestModalDialog.showDialog();
  }

  onRunTestResult(event:PromotionTestVO) {
    LogUtil.debug('ShopPromotionsComponent onRunTestResult', event);
    if (event != null && this.selectedShop != null) {
      this.loading = true;

      event.shopCode = this.selectedShop.code;
      event.currency = this.selectedCurrency;

      this._promotionService.testPromotions(event).subscribe(
        cart => {
          this.loading = false;
          LogUtil.debug('ShopPromotionsComponent onTestRules', cart);
          this.viewMode = ShopPromotionsComponent.PROMOTIONS_TEST;
          this.testCart = cart;
        }
      );

    }
  }


  onFilterChange(event:any) {
    this.promotions.searchContext.start = 0; // changing filter means we need to start from first page
    this.delayedFiltering.delay();
  }

  onRefreshHandler() {
    LogUtil.debug('ShopPromotionsComponent refresh handler');
    if (UserEventBus.getUserEventBus().current() != null) {
      this.presetFromCookie();
      this.getFilteredPromotions();
    }
  }

  onPageSelected(page:number) {
    LogUtil.debug('ShopPromotionsComponent onPageSelected', page);
    this.promotions.searchContext.start = page;
    this.delayedFiltering.delay();
  }

  onSortSelected(sort:Pair<string, boolean>) {
    LogUtil.debug('ShopPromotionsComponent ononSortSelected', sort);
    if (sort == null) {
      this.promotions.searchContext.sortBy = null;
      this.promotions.searchContext.sortDesc = false;
    } else {
      this.promotions.searchContext.sortBy = sort.first;
      this.promotions.searchContext.sortDesc = sort.second;
    }
    this.delayedFiltering.delay();
  }

  onPromotionSelected(data:PromotionVO) {
    LogUtil.debug('ShopPromotionsComponent onPromotionSelected', data);
    this.selectedPromotion = data;
  }

  onPromotionChanged(event:FormValidationEvent<PromotionVO>) {
    LogUtil.debug('ShopPromotionsComponent onPromotionChanged', event);
    this.changed = true;
    this.validForSave = event.valid;
    this.validForSaveAndDisabled = this.validForSave && !event.source.enabled;
    this.promotionEdit = event.source;
  }

  onSearchHelpToggle() {
    this.searchHelpShow = !this.searchHelpShow;
  }


  onSearchCode() {
    this.promotionFilter = '#';
    this.searchHelpShow = false;
  }

  onSearchCondition() {
    this.promotionFilter = '?';
    this.searchHelpShow = false;
  }

  onSearchEnabled() {
    this.promotionFilter = '++';
    this.searchHelpShow = false;
    this.getFilteredPromotions();
  }

  onSearchDate() {
    this.promotionFilter = UiUtil.exampleDateSearch();
    this.searchHelpShow = false;
    this.getFilteredPromotions();
  }

  onForceShowAll() {
    this.forceShowAll = !this.forceShowAll;
    this.getFilteredPromotions();
  }

  onBackToList() {
    LogUtil.debug('ShopPromotionsComponent onBackToList handler');
    if (this.viewMode === ShopPromotionsComponent.PROMOTION || this.viewMode === ShopPromotionsComponent.PROMOTIONS_TEST) {
      this.promotionEdit = null;
      this.viewMode = ShopPromotionsComponent.PROMOTIONS;
    }
  }

  onRowNew() {
    LogUtil.debug('ShopPromotionsComponent onRowNew handler');
    this.changed = false;
    this.validForSave = false;
    this.validForSaveAndDisabled = false;
    if (this.viewMode === ShopPromotionsComponent.PROMOTIONS) {
      this.promotionEdit = this.newPromotionInstance();
      this.viewMode = ShopPromotionsComponent.PROMOTION;
    }
  }

  onRowDelete(row:any) {
    LogUtil.debug('ShopPromotionsComponent onRowDelete handler', row);
    this.deleteValue = row.name;
    this.deleteConfirmationModalDialog.show();
  }

  onRowDeleteSelected() {
    if (this.selectedPromotion != null) {
      this.onRowDelete(this.selectedPromotion);
    }
  }

  onRowEnableSelected() {
    if (this.selectedPromotion != null) {
      this.deleteValue = this.selectedPromotion.name;
      this.disableConfirmationModalDialog.show();
    }
  }


  onRowEditPromotion(row:PromotionVO) {
    LogUtil.debug('ShopPromotionsComponent onRowEditPromotion handler', row);
    this.promotionEdit = Util.clone(row);
    this.changed = false;
    this.validForSave = false;
    this.validForSaveAndDisabled = false;
    this.viewMode = ShopPromotionsComponent.PROMOTION;
  }

  onRowEditSelected() {
    if (this.selectedPromotion != null) {
      this.onRowEditPromotion(this.selectedPromotion);
    }
  }

  onRowCopySelected() {
    if (this.selectedPromotion != null) {
      let copy:PromotionVO = Util.clone(this.selectedPromotion);
      copy.promotionId = 0;
      copy.enabled = false;
      copy.shopCode = this.selectedShopCode;
      this.onRowEditPromotion(copy);
    }
  }


  onSaveHandler() {

    if (this.validForSaveAndDisabled && this.changed) {

      if (this.promotionEdit != null) {

        LogUtil.debug('ShopPromotionsComponent Save handler promotion', this.promotionEdit);

        this.loading = true;
        this._promotionService.savePromotion(this.promotionEdit).subscribe(
            rez => {
              LogUtil.debug('ShopPromotionsComponent promotion changed', rez);
              this.changed = false;
              this.selectedPromotion = rez;
              this.promotionEdit = null;
              this.viewMode = ShopPromotionsComponent.PROMOTIONS;
              this.loading = false;
              this.getFilteredPromotions();
            }
        );
      }

    }

  }

  onDiscardEventHandler() {
    LogUtil.debug('ShopPromotionsComponent discard handler');
    if (this.viewMode === ShopPromotionsComponent.PROMOTION) {
      if (this.selectedPromotion != null) {
        this.onRowEditSelected();
      } else {
        this.onRowNew();
      }
    }
  }

  onDeleteConfirmationResult(modalresult: ModalResult) {
    LogUtil.debug('ShopPromotionsComponent onDeleteConfirmationResult modal result is ', modalresult);
    if (ModalAction.POSITIVE === modalresult.action) {

      if (this.selectedPromotion != null) {
        LogUtil.debug('ShopPromotionsComponent onDeleteConfirmationResult', this.selectedPromotion);

        this.loading = true;
        this._promotionService.removePromotion(this.selectedPromotion).subscribe(res => {
          LogUtil.debug('ShopPromotionsComponent removePromotion', this.selectedPromotion);
          this.selectedPromotion = null;
          this.promotionEdit = null;
          this.loading = false;
          this.getFilteredPromotions();
        });
      }
    }
  }


  onDisableConfirmationResult(modalresult: ModalResult) {
    LogUtil.debug('ShopPromotionsComponent onDisableConfirmationResult modal result is ', modalresult);
    if (ModalAction.POSITIVE === modalresult.action) {

      if (this.selectedPromotion != null) {
        this.loading = true;
        this._promotionService.updatePromotionDisabledFlag(this.selectedPromotion, this.selectedPromotion.enabled).subscribe( done => {
          LogUtil.debug('ShopPromotionsComponent updateDisabledFlag', done);
          this.selectedPromotion.enabled = !this.selectedPromotion.enabled;
          if (this.promotionEdit != null && this.selectedPromotion.promotionId == this.promotionEdit.promotionId) {
            this.promotionEdit = Util.clone(this.promotionEdit); // Trigger form INIT
            this.promotionEdit.enabled = this.selectedPromotion.enabled;
            this.validForSaveAndDisabled = this.validForSave && !this.promotionEdit.enabled;
          } else {
            this.changed = false;
            this.validForSave = false;
            this.validForSaveAndDisabled = false;
          }
          this.loading = false;
        });
      }
    }
  }

  onClearFilter() {

    this.promotionFilter = '';
    this.getFilteredPromotions();

  }


  private getFilteredPromotions() {
    this.promotionFilterRequired = !this.forceShowAll && (this.promotionFilter == null || this.promotionFilter.length < 2);

    LogUtil.debug('ShopPromotionsComponent getFilteredPromotions' + (this.forceShowAll ? ' forcefully': ''));

    if (this.selectedShop != null && this.selectedCurrency != null && !this.promotionFilterRequired) {
      this.loading = true;

      let types:string[] = [];
      ShopPromotionsComponent._promoTypes.forEach((_type:Pair<AttributeVO, boolean>) => {
        if (_type.second) {
          types.push(_type.first.val);
        }
      });

      let actions:string[] = [];
      ShopPromotionsComponent._promoActions.forEach((_action:Pair<AttributeVO, boolean>) => {
        if (_action.second) {
          actions.push(_action.first.val);
        }
      });

      this.promotions.searchContext.parameters.filter = [ this.promotionFilter ];
      this.promotions.searchContext.parameters.shopCode = [ this.selectedShop.code ];
      this.promotions.searchContext.parameters.currency = [ this.selectedCurrency ];
      this.promotions.searchContext.parameters.types = types;
      this.promotions.searchContext.parameters.actions = actions;
      this.promotions.searchContext.size = Config.UI_TABLE_PAGE_SIZE;

      this._promotionService.getFilteredPromotions(this.promotions.searchContext).subscribe( allpromotions => {
        LogUtil.debug('ShopPromotionsComponent getFilteredPromotions', allpromotions);
        this.promotions = allpromotions;
        this.selectedPromotion = null;
        this.promotionEdit = null;
        this.viewMode = ShopPromotionsComponent.PROMOTIONS;
        this.changed = false;
        this.validForSave = false;
        this.validForSaveAndDisabled = false;
        this.loading = false;
      });
    } else {
      this.promotions = this.newSearchResultInstance();
      this.selectedPromotion = null;
      this.promotionEdit = null;
      this.viewMode = ShopPromotionsComponent.PROMOTIONS;
      this.changed = false;
      this.validForSave = false;
      this.validForSaveAndDisabled = false;
    }
  }

}
