<template>
  <div class="pricing-plans-comp s-no-select" :class="planClass">

    <!-- Top badge showing plan highlight -->
    <section class="pricing-plans-top" v-if="topBadgeText">
      <span>{{topBadgeText}}</span>
    </section>

    <!-- Plan header section -->
    <section class="pricing-plans-packedname">
      <s-icon class="plan-main-icon" :icon-image="iconUrl" />

      <!-- Regular plan name display -->
      <h4 v-if="!isGold">{{ planName }}</h4>

      <!-- Gold plan name with image -->
      <h4 v-else class="gold-plan-title">
        <span class="gold-prefix">GOLD</span>
        <img src="/assets/images/plan_gold_star.svg" class="gold-star-icon" alt="star">
        <span class="gold-suffix">{{ goldNumber }}</span>
      </h4>

      <span>${{ currentPrice }}{{ isLite ? '' : '.95' }}</span>
      <small>{{ isLite ? ' /Monthly' : (togglePrice ? ' /Yearly' : ' /Monthly') }}</small>

      <!-- Add tagline below price -->
      <div class="plan-tagline">{{ currentPlanTagline }}</div>
    </section>

    <!--    Features section -->
    <section class="pricing-plans-details pricing-plans-array">
      <!-- Lite plan features -->
      <div v-if="isLite">
    <span v-for="(feature, index) in liteFeatures" :key="index" class="s-text-medium">
      {{ feature }}
      <hr class="s-hr-light" v-if="index < liteFeatures.length - 1">
    </span>
      </div>

      <!-- All other plans (Basic, Pro, Master, Gold) -->
      <div class="details-wrapper" v-else>
        <!-- Show inheritance for non-Gold plans -->
        <div v-if="!showMoreFeatures && !isGold" class="s-text-medium">
          Everything in {{ getParentPlan() }} and:
        </div>
        <!-- Show inheritance for Gold plans -->
        <div v-if="!showMoreFeatures && isGold" class="s-text-medium">
          Includes all Master features
        </div>
        <br v-if="!showMoreFeatures">

        <!-- Single dynamic features loop for ALL plans -->
        <div v-for="feature in currentPlanFeatures" :key="feature.key">
          <div v-if="feature.type === 'text'">
            <span class="s-text-medium has-badge"><b>{{ feature.name }}</b></span>
            <s-badge :class="getBadgeClass(feature.key)">{{ feature.isDetail }}</s-badge>
            <br>
          </div>
          <div v-if="feature.type === 'icon'">
            <span class="s-text-medium default">{{ feature.name }}</span><br>
          </div>
        </div>
      </div>

      <!-- Show more/less toggle for non-Lite plans -->
      <div class="show-more-features" v-if="!isLite && hasMoreFeatures">
    <span class="s-text-link s-text-r" @click="toggleShowMore">
      {{ !showMoreFeatures ? 'Show Plan Details' : 'Hide Details' }}
    </span>
      </div>
    </section>


    <!-- CTA section -->
    <section class="pricing-plans-cta">
      <div class="toggle-billing" v-if="!isLite" @click="toggleBilling">
       <span class="bill-title s-text-medium">
         <s-icon
           :class="{'s-icon-blue-darker': togglePrice}"
           :icon-font="togglePrice ? 's-icon-checkbox-selected' : 's-icon-checkbox-none'"
         />Bill Yearly
       </span>
        <span class="save-title">
         <s-icon v-if="!togglePrice" class="s-icon-promo" icon-font="s-icon-action"/>
         <s-icon v-if="togglePrice" class="s-icon-success green" icon-font="s-icon-lock"/>
         {{ togglePrice ? 'Saved ' : 'Save ' }}  <b><span class="save-value" :class="{'bill-yearly': togglePrice}">{{ saveValue }}</span></b> / per year
       </span>
      </div>

      <s-button
        class="s-button-upgrade-fill"
        :class="buttonClass"
        :btn-link="ctaLink">
        {{ ctaText }}
      </s-button>

      <div v-if="isGold3 || isGold4" class="limited-capacity">
        <s-icon class="s-icon-warning" icon-font="s-icon-info-outline s-icon-rotate"/>
        <span  class="save-title limited-title">Limited Capacity</span>
      </div>
    </section>
  </div>
</template>

<script>
import SButton from "../components/SButton.vue";
import SIcon from "../components/SIcon.vue";
import SBadge from "../components/SBadge.vue";

export default {
  item: 'PricingPlans',
  components: {
    SBadge,
    SIcon,
    SButton,
  },
  props: {
    planName: String,
  },
  data() {
    return {
      // ADD: Show more features toggle
      showMoreFeatures: false,

      // Existing toggle price
      togglePrice: false,

      planIcons: {
        'Basic': '/images/plan_basic_logo_SVG.svg',
        'Pro': '/images/plan_pro_logo_SVG.svg',
        'Master': '/images/plan_master_logo_SVG.svg',
        'Lite': '/images/plan_lite_logo_SVG.svg',
      },

      liteFeatures: [
        'Fast Downloads',
        'Uploads',
        'Storage Cleanup',
        'Tasks Slots',
        'Search everywhere',
        'Sync your cloud sources',
      ],


      // ADD: Plan taglines
      planTaglines: {
        lite: 'Perfect for quick one-offs',
        basic: 'Perfect for steady weekend use',
        pro: 'Perfect for large libraries & private trackers',
        master: 'Perfect for power users & hoarders',
        gold1: 'Perfect for entire-library backups',
        gold2: 'Perfect for serious archivists',
        gold3: 'Perfect for creators & small teams',
        gold4: 'Perfect for enterprise-scale needs'
      },

      // ADD: Plan descriptions (for future use in plan-selection drawer)
      planDescriptions: {
        lite: 'Ideal when you just need a link fetched now and then without keeping your PC on.',
        basic: 'Great for weekly downloads and small libraries that are starting to grow.',
        pro: 'Perfect for big collections and private trackers with extra slots to keep ratios healthy.',
        master: 'A full 1TB workspace with WebDAV mounts and priority handling—ideal for nonstop queues and 4K streaming.',
        gold1: 'Gold delivers terabytes, uncapped speeds, and premium routing so storage or bandwidth never slow you down.',
        gold2: 'Gold delivers terabytes, uncapped speeds, and premium routing so storage or bandwidth never slow you down.',
        gold3: 'Gold delivers terabytes, uncapped speeds, and premium routing so storage or bandwidth never slow you down.',
        gold4: 'Gold delivers terabytes, uncapped speeds, and premium routing so storage or bandwidth never slow you down.'
      },

      // ADD: Tooltip content
      tooltipContent: {
        parallelTasks: 'How many files Seedr fetches at the same time. Extra tasks wait in line and start automatically when a slot is free.'
      },

      featuresNames: [
        // ---- PLAN INFO ----
        { key: 'planListName', show: false, isShort: false, type: 'icon', name: 'Plan Name', isDetail: '' },
        { key: 'planInheritance', show: false, isShort: false, type: 'icon', name: 'Plan inheritance', isDetail: '' },
        { key: 'storage', show: false, isShort: false, type: 'text', name: 'Storage', isDetail: '' },
        { key: 'taskSlots', show: false, isShort: false, type: 'text', name: 'Task slots', isDetail: '' },
        { key: 'uploadSlots', show: false, isShort: false, type: 'text', name: 'Upload slots', isDetail: '' },

        // ---- STREAMING FEATURES ----
        { key: 'streaming500p', show: false, isShort: false, type: 'icon', name: '500p streaming', isDetail: '' },
        { key: 'streamingHD', show: false, isShort: false, type: 'icon', name: 'HD streaming (720p)', isDetail: '' },
        { key: 'streamingFHD', show: false, isShort: false, type: 'icon', name: 'Full-HD streaming (1080p)', isDetail: '' },
        { key: 'streaming4K', show: false, isShort: false, type: 'icon', name: '4K streaming (2160p)', isDetail: '' },
        { key: 'smartGrabber', show: false, isShort: false, type: 'icon', name: 'Smart link grabber', isDetail: '' },

        // ---- MOUNTS (FTP/WebDAV) ----
        { key: 'ftpMount', show: false, isShort: false, type: 'icon', name: 'FTP mount', isDetail: '' },
        { key: 'webdavMount', show: false, isShort: false, type: 'icon', name: 'WebDAV mount', isDetail: '' },
        { key: 'sftpAutomation', show: false, isShort: false, type: 'icon', name: 'SFTP automation', isDetail: '' },

        // ---- EXTRA FEATURES ----
        { key: 'privateTrackers', show: false, isShort: false, type: 'icon', name: 'Private tracker support', isDetail: '' },
        { key: 'priorityQueue', show: false, isShort: false, type: 'icon', name: 'Priority queue', isDetail: '' },
        { key: 'seedingRatio', show: false, isShort: false, type: 'icon', name: 'Seeding ratio', isDetail: '' },

        // ---- GOLD FEATURES ----
        { key: 'uncappedSpeeds', show: false, isShort: false, type: 'icon', name: 'Uncapped speeds', isDetail: '' },
        { key: 'premiumPriority', show: false, isShort: false, type: 'icon', name: 'Premium queue priority', isDetail: '' },
        { key: 'dedicatedSupport', show: false, isShort: false, type: 'icon', name: 'Dedicated priority support', isDetail: '' },
        { key: 'highestThroughput', show: false, isShort: false, type: 'icon', name: 'Highest throughput', isDetail: '' },
      ],

      // ADD: Plan features (copied from SPlanFeatures.vue)
      planFeatures: {
        lite: {
          _meta: {
            price: '3.95',
            ctaText: 'Go Lite',
            ctaLink: 'https://www.seedr.cc/paythrough?billing_plan_id=400',
            topBadge: 'Available Now'
          },
          storage: { show: true, isShort: true, isDetail: '10GB', name: 'Storage', type: 'text' },
          taskSlots: { show: true, isShort: true, isDetail: '1', name: 'Task Slots', type: 'text' },
          fastDownloads: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Fast Downloads', type: 'icon' },
          uploads: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Uploads', type: 'icon' },
          storageCleanup: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Storage Cleanup', type: 'icon' },
          searchEverywhere: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Search everywhere', type: 'icon' },
          syncCloudSources: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Sync your cloud sources', type: 'icon' },
        },

        basic: {
          _meta: {
            monthlyPrice: '7',
            yearlyPrice: '69',
            saveValue: '13.90',
            monthlyPlanId: 24,
            yearlyPlanId: 23,
            ctaText: 'Select Plan'
          },
          storage: { show: true, isShort: true, isDetail: '50GB', name: 'Storage', type: 'text' },
          taskSlots: { show: true, isShort: true, isDetail: '2', name: 'Tasks Slots', type: 'text' },
          support: { show: true, isShort: false, isDetail: 'PREMIUM', name: 'Support', type: 'text' },
          streamingHD: { show: true, isShort: true, isDetail: 's-icon-action', name: 'HD streaming', detail: '720p', type: 'icon' },
          ftpMount: { show: true, isShort: true, isDetail: 's-icon-action', name: 'FTP mount', type: 'icon' },
          seedingRatio: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Ratio 1:1 or 12h seeding', type: 'icon' },
        },

        pro: {
          _meta: {
            topBadge: 'Most Popular',
            monthlyPrice: '12',
            yearlyPrice: '99',
            saveValue: '19.90',
            monthlyPlanId: 12,
            yearlyPlanId: 13,
            ctaText: 'Select Plan'
          },
          storage: { show: true, isShort: true, isDetail: '150GB', name: 'Storage', type: 'text' },
          taskSlots: { show: true, isShort: true, isDetail: '8', name: 'Tasks Slots', type: 'text' },
          support: { show: true, isShort: false, isDetail: 'PREMIUM', name: 'Support', type: 'text' },
          streamingFHD: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Full-HD streaming', detail: '1080p', type: 'icon' },
          privateTrackers: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Private tracker', type: 'icon' },
          ftpMount: { show: true, isShort: false, isDetail: 's-icon-action', name: 'FTP mount', type: 'icon' },
          seedingRatio: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Ratio 2:1 or 48h seeding', type: 'icon' },
        },

        master: {
          _meta: {
            monthlyPrice: '19',
            yearlyPrice: '199',
            saveValue: '39.90',
            monthlyPlanId: 20,
            yearlyPlanId: 21,
            ctaText: 'Select Plan'
          },
          storage: { show: true, isShort: true, isDetail: '1TB', name: 'Storage', type: 'text' },
          taskSlots: { show: true, isShort: true, isDetail: '25', name: 'Tasks Slots', type: 'text' },
          support: { show: true, isShort: false, isDetail: 'PREMIUM', name: 'Support', type: 'text' },
          streaming4K: { show: true, isShort: true, isDetail: 's-icon-action', name: '4K streaming', detail: '2160p', type: 'icon' },
          webdavMount: { show: true, isShort: true, isDetail: 's-icon-action', name: 'WebDAV mount (+', type: 'icon' },
          priorityQueue: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Priority queue', type: 'icon' },
          seedingRatio: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Ratio 5:1 or 120h seeding', type: 'icon' },
        },

        gold1: {
          _meta: {
            monthlyPrice: '34',
            yearlyPrice: '349',
            saveValue: '69.90',
            monthlyPlanId: 406,
            yearlyPlanId: 407,
            ctaText: 'Upgrade Now',
          },
          storage: { show: true, isShort: true, isDetail: '2TB', name: 'Storage', type: 'text' },
          taskSlots: { show: true, isShort: true, isDetail: '35', name: 'Tasks Slots', type: 'text' },
          uploadSlots: { show: true, isShort: true, isDetail: '50', name: 'Upload Slots', type: 'text' },
          uncappedSpeeds: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Uncapped speeds', type: 'icon' },
          premiumPriority: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Premium queue priority', type: 'icon' },
          ftpAccess: { show: true, isShort: false, isDetail: 's-icon-action', name: 'FTP/SFTP Access', type: 'icon' },
          seedingRatio: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Ratio 5:1 or 240h seeding', type: 'icon' },
        },

        gold2: {
          _meta: {
            topBadge: 'Recommended',
            monthlyPrice: '49',
            yearlyPrice: '499',
            saveValue: '99.90',
            monthlyPlanId: 408,
            yearlyPlanId: 409,
            ctaText: 'Upgrade Now',
          },
          storage: { show: true, isShort: true, isDetail: '3TB', name: 'Storage', type: 'text' },
          taskSlots: { show: true, isShort: true, isDetail: '50', name: 'Tasks Slots', type: 'text' },
          uploadSlots: { show: true, isShort: true, isDetail: '70', name: 'Upload Slots', type: 'text' },
          uncappedSpeeds: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Uncapped speeds', type: 'icon' },
          premiumPriority: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Premium queue priority', type: 'icon' },
          ftpAccess: { show: true, isShort: false, isDetail: 's-icon-action', name: 'FTP/SFTP Access', type: 'icon' },
          seedingRatio: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Ratio 5:1 or 240h seeding', type: 'icon' },
        },

        gold3: {
          _meta: {
            monthlyPrice: '79',
            yearlyPrice: '799',
            saveValue: '169.90',
            monthlyPlanId: 410,
            yearlyPlanId: 411,
            ctaText: 'Upgrade Now',
          },
          storage: { show: true, isShort: true, isDetail: '5TB', name: 'Storage', type: 'text' },
          taskSlots: { show: true, isShort: true, isDetail: '70', name: 'Tasks Slots', type: 'text' },
          uploadSlots: { show: true, isShort: true, isDetail: '100', name: 'Upload Slots', type: 'text' },
          uncappedSpeeds: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Uncapped speeds', type: 'icon' },
          premiumPriority: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Premium queue priority', type: 'icon' },
          ftpAccess: { show: true, isShort: false, isDetail: 's-icon-action', name: 'FTP/SFTP Access', type: 'icon' },
          dedicatedSupport: { show: true, isShort: false, isDetail: 's-icon-action', name: 'Dedicated priority support', type: 'icon' },
          seedingRatio: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Ratio 5:1 or 336h seeding', type: 'icon' },
        },

        gold4: {
          _meta: {
            monthlyPrice: '139',
            yearlyPrice: '1399',
            saveValue: '259.90',
            monthlyPlanId: 412,
            yearlyPlanId: 413,
            ctaText: 'Upgrade Now',
          },
          storage: { show: true, isShort: true, isDetail: '10TB', name: 'Storage', type: 'text' },
          taskSlots: { show: true, isShort: true, isDetail: '100', name: 'Tasks Slots', type: 'text' },
          uploadSlots: { show: true, isShort: true, isDetail: '130', name: 'Upload Slots', type: 'text' },
          uncappedSpeeds: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Uncapped speeds', type: 'icon' },
          premiumPriority: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Premium queue priority', type: 'icon' },
          ftpAccess: { show: true, isShort: false, isDetail: 's-icon-action', name: 'FTP/SFTP Access', type: 'icon' },
          dedicatedSupport: { show: true, isShort: false, isDetail: 's-icon-action', name: 'Dedicated priority support', type: 'icon' },
          highestThroughput: { show: true, isShort: false, isDetail: 's-icon-action', name: 'Highest throughput · limited capacity', type: 'icon' },
          seedingRatio: { show: true, isShort: true, isDetail: 's-icon-action', name: 'Ratio 5:1 or 720h seeding', type: 'icon' },
        },
      },
    };
  },
  computed: {
    // Determine which plan type we're dealing with
    planType() {
      if (this.planName === 'Lite') return 'lite';
      if (this.planName === 'Basic') return 'basic';
      if (this.planName === 'Pro') return 'pro';
      if (this.planName === 'Master') return 'master';
      if (this.planName === 'GOLD One') return 'gold1';
      if (this.planName === 'GOLD Two') return 'gold2';
      if (this.planName === 'GOLD Three') return 'gold3';
      if (this.planName === 'GOLD Four') return 'gold4';
      return 'basic'; // Default fallback
    },

    // Helper flags for conditional rendering
    isLite() {
      return this.planType === 'lite';
    },
    isBasic() {
      return this.planType === 'basic';
    },
    isPro() {
      return this.planType === 'pro';
    },
    isMaster() {
      return this.planType === 'master';
    },
    isGold1() {
      return this.planType === 'gold1';
    },
    isGold2() {
      return this.planType === 'gold2';
    },
    isGold3() {
      return this.planType === 'gold3';
    },
    isGold4() {
      return this.planType === 'gold4';
    },
    isGold() {
      return this.isGold1 || this.isGold2 || this.isGold3 || this.isGold4;
    },




    // ADD: Get tagline for current plan
    currentPlanTagline() {
      return this.planTaglines[this.planType] || '';
    },

    // ADD: Get description for current plan
    currentPlanDescription() {
      return this.planDescriptions[this.planType] || '';
    },

    // ADD: Get features for current plan (MOVED from computed to computed properly)
    currentPlanFeatures() {
      return this.features(this.planType);
    },

    currentPlanData() {
      return this.planFeatures[this.planType]?._meta || {};
    },

    // ADD: Check if plan has more features to show
    hasMoreFeatures() {
      if (this.isLite) return false;

      const planOverrides = this.planFeatures[this.planType];
      if (!planOverrides) return false;

      // Count features that have isShort: true vs all features that show: true
      const shortFeatures = this.featuresNames.filter(feature => {
        const override = planOverrides[feature.key];
        return override && override.show && override.isShort;
      });

      const allFeatures = this.featuresNames.filter(feature => {
        const override = planOverrides[feature.key];
        return override && override.show;
      });

      return allFeatures.length > shortFeatures.length;
    },

    // Get top badge text
    topBadgeText() {
      return this.currentPlanData.topBadge || '';
    },

    // Get gold plan number (One, Two, etc.)
    goldNumber() {
      if (!this.isGold) return '';
      const parts = this.planName.split(' ');
      if (parts.length >= 2) {
        return parts[parts.length - 1];
      }
      return '';
    },

    // CSS classes based on plan type
    planClass() {
      return {
        'pricing-plans-lite': this.isLite,
        'pricing-plans-basic': this.isBasic,
        'pricing-plans-border pricing-plans-pro': this.isPro,
        'pricing-plans-master': this.isMaster,
        'pricing-plans-gold': this.isGold,
        'pricing-plans-gold1': this.isGold1,
        'pricing-plans-gold2': this.isGold2,
        'pricing-plans-gold3': this.isGold3,
        'pricing-plans-gold4': this.isGold4,
      };
    },

    // Button class based on plan type
    buttonClass() {
      return {
        'lite': this.isLite,
        'basic': this.isBasic,
        'pro': this.isPro,
        'master': this.isMaster,
        'gold': this.isGold,
        'gold1': this.isGold1,
        'gold2': this.isGold2,
        'gold3': this.isGold3,
        'gold4': this.isGold4,
        'premium': !this.isLite
      };
    },



    // Derived values from plan data
    planStorage() {
      return this.currentPlanData.storage;
    },
    taskSlots() {
      return this.currentPlanData.taskSlots;
    },
    uploadSlots() {
      return this.currentPlanData.uploadSlots;
    },
    saveValue() {
      return this.currentPlanData.saveValue;
    },
    currentPrice() {
      const meta = this.currentPlanData;
      if (this.isLite) return meta.price || '3.95';
      return this.togglePrice ? meta.yearlyPrice : meta.monthlyPrice;
    },

    billingPlanId() {
      if (this.isLite) return null;
      const meta = this.currentPlanData;
      return this.togglePrice ? meta.yearlyPlanId : meta.monthlyPlanId;
    },
    iconUrl() {
      return this.planIcons[this.planName] || '';
    },
    ctaText() {
      return this.currentPlanData.ctaText || 'Select Plan';
    },
    ctaLink() {
      if (this.isLite) return '/payment?billing_plan_id=' + this.billingPlanId;
      return '/payment?billing_plan_id=' + this.billingPlanId;
    }
  },
  methods: {

    getParentPlan() {
      if (this.isPro) return 'Basic';
      if (this.isMaster) return 'Pro';
      if (this.isGold) return 'Master';
      return 'Lite';
    },

    features(planNameList) {
      if (planNameList && this.planFeatures && this.planFeatures[planNameList]) {
        return this.buildFeatureList(planNameList);
      }
      return [];
    },

    buildFeatureList(planKey) {
      const planOverrides = this.planFeatures[planKey];
      const features = [];
      const shouldShowAll = this.showMoreFeatures;

      this.featuresNames.forEach(feature => {
        const override = planOverrides[feature.key];
        if (override && override.show) {
          const shouldShow = shouldShowAll ? true : override.isShort;
          if (shouldShow) {
            features.push({
              isDetail: override.isDetail,
              name: override.name || feature.name,
              key: feature.key,
              type: override.type || feature.type
            });
          }
        }
      });
      return features;
    },

    toggleShowMore() {
      this.showMoreFeatures = !this.showMoreFeatures;
    },

    toggleBilling() {
      this.togglePrice = !this.togglePrice;
    },


    // ADD: Get badge color class based on feature type
    getBadgeClass(featureKey) {
      if (featureKey === 'storage') return 's-badge-green storage';
      if (featureKey === 'taskSlots') return 's-badge-blue';
      if (featureKey === 'uploadSlots') return 's-badge-grey';
      if (featureKey === 'support') return 's-badge-premium';
      return 's-badge-blue'; // default
    },
  }
};
</script>
