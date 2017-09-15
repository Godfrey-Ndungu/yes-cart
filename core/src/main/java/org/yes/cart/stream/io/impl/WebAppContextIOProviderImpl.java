/*
 * Copyright 2009 Denys Pavlov, Igor Azarnyi
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package org.yes.cart.stream.io.impl;

import org.springframework.web.context.ServletContextAware;
import org.yes.cart.stream.io.IOProvider;

import javax.servlet.ServletContext;
import java.io.File;
import java.util.Map;

/**
 * User: denispavlov
 * Date: 30/08/2014
 * Time: 15:36
 */
public class WebAppContextIOProviderImpl extends AbstractFileSystemIOProviderImpl implements IOProvider, ServletContextAware {

    private static final String PROTOCOL1 = "context:" + File.separator + File.separator;
    private static final String PROTOCOL2 = "context://";

    private ServletContext servletContext;


    /** {@inheritDoc} */
    @Override
    public File resolveFileFromUri(final String uri, final Map<String, Object> context) {

        final String absolutePath;
        if (uri.startsWith(PROTOCOL1)) {
            absolutePath = uri.substring(PROTOCOL1.length());
        } else if (uri.startsWith(PROTOCOL2)) {
            absolutePath = uri.substring(PROTOCOL2.length());
        } else {
            absolutePath = uri;
        }

        final String ctxPath = servletContext.getRealPath(absolutePath);
        if (ctxPath == null) {
            throw new IllegalArgumentException("Specified path cannot be resolved: " + uri);
        }
        return new File(getOsAwarePath(ctxPath));

    }

    /** {@inheritDoc} */
    @Override
    public boolean supports(final String uri) {
        return uri != null && (uri.startsWith(PROTOCOL1) || uri.startsWith(PROTOCOL2) ||
                !uri.startsWith(File.separator));
    }

    /** {@inheritDoc} */
    @Override
    public void setServletContext(final ServletContext servletContext) {
        this.servletContext = servletContext;
    }
}
